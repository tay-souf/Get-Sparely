import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/data/cubits/auth/user_profile_cubit.dart';
import 'package:eClassify/data/cubits/system/user_details.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/phone_input.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/image_picker.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  final String from;
  final bool? navigateToHome;
  final bool? popToCurrent;

  const UserProfileScreen({
    super.key,
    required this.from,
    this.navigateToHome,
    this.popToCurrent,
  });

  @override
  State<UserProfileScreen> createState() => UserProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    return MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        from: arguments['from'] as String,
        popToCurrent: arguments['popToCurrent'] as bool?,
        navigateToHome: arguments['navigateToHome'] as bool?,
      ),
    );
  }
}

class UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PhoneInputController phoneController = PhoneInputController();
  late final TextEditingController nameController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String? name, email, address;
  File? fileUserimg;
  bool isNotificationsEnabled = true;
  bool isPersonalDetailShow = true;
  bool? isLoading;
  final ImagePicker picker = ImagePicker();
  PickImage profileImagePicker = PickImage();
  bool isFromLogin = false;

  @override
  void initState() {
    super.initState();
    isFromLogin = widget.from == 'login';

    nameController.text = (HiveUtils.getUserDetails().name) ?? "";
    emailController.text = HiveUtils.getUserDetails().email ?? "";
    addressController.text = HiveUtils.getUserDetails().address ?? "";

    if (isFromLogin) {
      isNotificationsEnabled = true;
      isPersonalDetailShow = true;
    } else {
      isNotificationsEnabled = HiveUtils.getUserDetails().notification == 1
          ? true
          : false;
      isPersonalDetailShow =
          HiveUtils.getUserDetails().isPersonalDetailShow == 1 ? true : false;
    }

    final user = context.read<UserDetailsCubit>().state.user;
    phoneController.phoneNumber = user?.mobile;
    phoneController.phoneCode = user?.countryCode;
    phoneController.regionCode = user?.regionCode;

    profileImagePicker.listener((files) {
      if (files != null && files.isNotEmpty) {
        setState(() {
          fileUserimg = files.first; // Assign picked image to fileUserimg
        });
      }
    });
  }

  @override
  void dispose() {
    profileImagePicker.dispose();
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: AppBar(
          backgroundColor: context.color.primaryColor,
          automaticallyImplyLeading: isFromLogin,
          title: CustomText('editprofile'.translate(context)),
        ),
        body: BlocListener<UserProfileCubit, UserProfileState>(
          listener: (context, state) {
            log('$state');
            if (state is UserProfileLoading) {
              LoadingWidgets.showLoader(context);
            }

            if (state is UserProfileSuccess) {
              LoadingWidgets.hideLoader(context);
              context.read<UserDetailsCubit>().copy(state.user);
              if (state.message != null) {
                HelperUtils.showSnackBarMessage(context, state.message!);
              }
              if (isFromLogin) {
                Future.delayed(Duration.zero, () {
                  if (widget.popToCurrent ?? false) {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  } else {
                    HelperUtils.killPreviousPages(context, Routes.main, {
                      "from": 'profile_screen',
                    });
                  }
                });
              } else {
                Navigator.pop(context);
              }
            }

            if (state is UserProfileFailure) {
              LoadingWidgets.hideLoader(context);
              HelperUtils.showSnackBarMessage(
                context,
                state.errorMessage,
                type: MessageType.error,
              );
            }
          },
          child: Padding(
            padding: Constant.appContentPadding,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 10,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: AlignmentDirectional.center,
                      child: buildProfilePicture(),
                    ),
                    buildTextField(
                      context,
                      title: "fullName",
                      controller: nameController,
                      validator: CustomTextFieldValidator.nullCheck,
                    ),
                    buildTextField(
                      context,
                      readOnly: [
                        AuthenticationType.email.name,
                        AuthenticationType.google.name,
                        AuthenticationType.apple.name,
                      ].contains(HiveUtils.getUserDetails().type),
                      title: "emailAddress",
                      controller: emailController,
                      validator: CustomTextFieldValidator.email,
                    ),
                    CustomText('phoneNumber'.translate(context)),
                    PhoneInput(
                      controller: phoneController,
                      readOnly:
                          HiveUtils.getUserDetails().type ==
                          AuthenticationType.phone.name,
                    ),
                    buildTextField(
                      context,
                      title: "addressLbl",
                      controller: addressController,
                      maxline: 5,
                      textInputAction: TextInputAction.newline,
                    ),
                    CustomText("notification".translate(context)),
                    buildEnableDisableSwitch(isNotificationsEnabled, (cgvalue) {
                      isNotificationsEnabled = cgvalue;
                      setState(() {});
                    }),
                    CustomText("showContactInfo".translate(context)),
                    buildEnableDisableSwitch(isPersonalDetailShow, (cgvalue) {
                      isPersonalDetailShow = cgvalue;
                      setState(() {});
                    }),
                    updateProfileBtnWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEnableDisableSwitch(bool value, Function(bool) onChangeFunction) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.color.textLightColor.withValues(alpha: 0.23),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
        color: context.color.secondaryColor,
      ),
      height: 60,
      width: double.infinity,
      padding: const EdgeInsetsDirectional.only(start: 16.0),
      child: Row(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            (value ? "enabled" : "disabled").translate(context),
            fontSize: context.font.large,
            color: context.color.textDefaultColor,
          ),
          CupertinoSwitch(
            activeTrackColor: context.color.territoryColor,
            value: value,
            onChanged: onChangeFunction,
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    int? maxline,
    TextInputAction? textInputAction,
  }) {
    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title.translate(context),
          color: context.color.textDefaultColor,
        ),
        CustomTextFormField(
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          // formaters: [FilteringTextInputFormatter.deny(RegExp(","))],
          fillColor: context.color.secondaryColor,
          action: textInputAction,
          maxLine: maxline,
        ),
      ],
    );
  }

  Widget getProfileImage() {
    if (fileUserimg != null) {
      return Image.file(fileUserimg!, fit: BoxFit.cover);
    } else {
      if (isFromLogin) {
        if (HiveUtils.getUserDetails().profile != null &&
            HiveUtils.getUserDetails().profile!.trim().isNotEmpty) {
          return UiUtils.getImage(
            HiveUtils.getUserDetails().profile!,
            fit: BoxFit.cover,
          );
        }

        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else if ((HiveUtils.getUserDetails().profile ?? "").trim().isEmpty) {
        return UiUtils.getSvg(
          AppIcons.defaultPersonLogo,
          color: context.color.territoryColor,
          fit: BoxFit.none,
        );
      } else {
        return UiUtils.getImage(
          HiveUtils.getUserDetails().profile!,
          fit: BoxFit.cover,
        );
      }
    }
  }

  Widget buildProfilePicture() {
    return Stack(
      children: [
        Container(
          height: 124,
          width: 124,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.color.territoryColor, width: 2),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            width: 106,
            height: 106,
            child: getProfileImage(),
          ),
        ),
        PositionedDirectional(
          bottom: 0,
          end: 0,
          child: InkWell(
            onTap: showPicker,
            child: Container(
              height: 37,
              width: 37,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.color.buttonColor,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
                color: context.color.territoryColor,
              ),
              child: SizedBox(
                width: 15,
                height: 15,
                child: UiUtils.getSvg(AppIcons.edit),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> validateData() async {
    if (_formKey.currentState!.validate()) {
      if (isFromLogin) {
        HiveUtils.setUserIsAuthenticated(true);
      }
      if (context.read<UserProfileCubit>().state is UserProfileLoading) {
        return;
      }
      context.read<UserProfileCubit>().updateUserProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        profileImagePath: fileUserimg?.path,
        address: addressController.text,
        mobile: phoneController.phoneNumber,
        notification: isNotificationsEnabled == true ? "1" : "0",
        phoneCode: phoneController.phoneCode,
        regionCode: phoneController.regionCode,
        personalDetail: isPersonalDetailShow == true ? 1 : 0,
      );
    }
  }

  void showPicker() {
    UiUtils.imagePickerBottomSheet(
      context,
      isRemovalWidget: fileUserimg != null && isFromLogin,
      callback: (bool isRemoved, ImageSource? source) async {
        if (isRemoved) {
          setState(() {
            fileUserimg = null;
          });
        } else if (source != null) {
          await profileImagePicker.pick(
            context: context,
            source: source,
            pickMultiple: false,
          );
        }
      },
    );
  }

  Widget updateProfileBtnWidget() {
    return UiUtils.buildButton(
      context,
      outerPadding: EdgeInsetsDirectional.only(top: 15),
      onPressed: validateData,
      height: 48,
      buttonTitle: "updateProfile".translate(context),
    );
  }
}
