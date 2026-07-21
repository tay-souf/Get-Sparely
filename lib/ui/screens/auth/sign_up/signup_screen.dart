import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/authentication_cubit.dart';
import 'package:eClassify/ui/screens/auth/sign_up/email_verification_screen.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/skip_button_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/login/lib/payloads.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static MaterialPageRoute route(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return SignupScreen();
      },
    );
  }

  @override
  CloudState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends CloudState<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void onTapSignup() async {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthenticationCubit>().setData(
        payload: EmailLoginPayload(
          email: _emailController.text,
          password: _passwordController.text,
          type: EmailLoginType.signup,
        ),
        type: AuthenticationType.email,
      );
      context.read<AuthenticationCubit>().authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: Platform.isIOS,
      child: AnnotatedRegion(
        value: UiUtils.getSystemUiOverlayStyle(
          context: context,
          statusBarColor: context.color.backgroundColor,
          navigationBarColor: context.color.backgroundColor,
        ),
        child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          bottomNavigationBar: termAndPolicyTxt(),
          appBar: AppBar(
            backgroundColor: context.color.primaryColor,
            automaticallyImplyLeading: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SkipButtonWidget(
                  onTap: () {
                    HelperUtils.killPreviousPages(context, Routes.main, {
                      "from": "login",
                      "isSkipped": true,
                    });
                  },
                ),
              ),
            ],
          ),
          body: BlocConsumer<AuthenticationCubit, AuthenticationState>(
            listener: (context, state) {
              if (state is AuthenticationSuccess) {
                if (state.type == AuthenticationType.email) {
                  if (!state.credential.user!.emailVerified) {
                    FirebaseAuth.instance.currentUser?.sendEmailVerification();

                    Navigator.push<dynamic>(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return EmailVerificationScreen(
                            email: _emailController.text,
                          );
                        },
                      ),
                    );
                  }
                }
              }

              if (state is AuthenticationFail) {
                //
              }
            },
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 18.0,
                      right: 18,
                      top: 23,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 66),
                        CustomText(
                          "welcome".translate(context),
                          fontSize: context.font.extraLarge,
                        ),
                        const SizedBox(height: 8),
                        CustomText(
                          "signUp".translate(context),
                          fontSize: context.font.large,
                          color: context.color.textColorDark.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextFormField(
                          controller: _emailController,
                          fillColor: context.color.secondaryColor,
                          validator: CustomTextFieldValidator.email,
                          hintText: "emailAddress".translate(context),
                          borderColor: context.color.textLightColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextFormField(
                          controller: _passwordController,
                          fillColor: context.color.secondaryColor,
                          obscureText: isObscure,
                          suffix: IconButton(
                            onPressed: () {
                              isObscure = !isObscure;
                              setState(() {});
                            },
                            icon: Icon(
                              !isObscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: context.color.textColorDark.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          hintText: "password".translate(context),
                          validator: CustomTextFieldValidator.password,
                          borderColor: context.color.textLightColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 36),
                        UiUtils.buildButton(
                          context,
                          onPressed: onTapSignup,
                          buttonTitle: "verifyEmailAddress".translate(context),
                          radius: 10,
                          disabled: false,
                          height: 46,
                          disabledColor: const Color.fromARGB(
                            255,
                            104,
                            102,
                            106,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              "alreadyHaveAcc".translate(context),
                              color: context.color.textColorDark.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              child: CustomText(
                                "login".translate(context),
                                showUnderline: true,
                                color: context.color.territoryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget termAndPolicyTxt() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            "bySigningUpLoggingIn".translate(context),
            color: context.color.textLightColor.withValues(alpha: 0.8),
            fontSize: context.font.small,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                child: CustomText(
                  "termsOfService".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "termsConditions".translate(context),
                    'param': Api.termsAndConditions,
                  },
                ),
              ),
              const SizedBox(width: 5.0),
              CustomText(
                "andTxt".translate(context),
                color: context.color.textLightColor.withValues(alpha: 0.8),
                fontSize: context.font.small,
              ),
              const SizedBox(width: 5.0),
              InkWell(
                child: CustomText(
                  "privacyPolicy".translate(context),
                  showUnderline: true,
                  color: context.color.territoryColor,
                  fontSize: context.font.small,
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  Routes.profileSettings,
                  arguments: {
                    'title': "privacyPolicy".translate(context),
                    'param': Api.privacyPolicy,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
