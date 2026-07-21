import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/select_category.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/widgets/image_adapter.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/custom_text_form_field.dart';
import 'package:eClassify/ui/screens/widgets/dynamic_field.dart';
import 'package:eClassify/ui/screens/widgets/phone_input.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/image_picker.dart';
import 'package:eClassify/utils/slug_formatter.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddItemDetails extends StatefulWidget {
  final List<CategoryModel>? breadCrumbItems;
  final bool? isEdit;

  const AddItemDetails({super.key, this.breadCrumbItems, required this.isEdit});

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder: (context) {
        return BlocProvider(
          create: (context) => FetchCustomFieldsCubit(),
          child: AddItemDetails(
            breadCrumbItems: arguments?['breadCrumbItems'],
            isEdit: arguments?['isEdit'],
          ),
        );
      },
    );
  }

  @override
  CloudState<AddItemDetails> createState() => _AddItemDetailsState();
}

class _AddItemDetailsState extends CloudState<AddItemDetails>
    with TickerProviderStateMixin {
  final PickImage swapImagePicker = PickImage(); // لصورة المقايضة
  final TextEditingController swapTargetController = TextEditingController(); // لـ swip_title
  final PickImage _pickTitleImage = PickImage();
  final PickImage itemImagePicker = PickImage();
  String titleImageURL = "";
  List<dynamic> mixedItemImageList = [];
  List<int> deleteItemImageList = [];
  late final GlobalKey<FormState> _formKey;

  // Shared fields
  final TextEditingController adSlugController = TextEditingController();
  final TextEditingController adPriceController = TextEditingController();
  final TextEditingController adAdditionalDetailsController = TextEditingController();
  final TextEditingController minSalaryController = TextEditingController();
  final TextEditingController maxSalaryController = TextEditingController();
  final PhoneInputController phoneInputController = PhoneInputController();

  // Language-specific fields
  Map<String, TextEditingController> adTitleControllers = {};
  Map<String, TextEditingController> adDescriptionControllers = {};

  int selectedLangIndex = 0;
  List languages = [];
  String defaultLangCode = '';
  TabController? _tabController;

  late List selectedCategoryList;
  ItemModel? item;

  // Flag to ensure translations are only populated once
  bool _translationsPopulated = false;

  final ValueNotifier<bool> _isValid = ValueNotifier(false);

  // نوع الفئة الرئيسية (مقايضة، تبرع، كلاسيك)
  String? get selectedCategoryType {
    if (widget.isEdit == true && item != null) {
      // في حالة التعديل، نحصل على النوع من الفئة المخزنة في item
      return item!.category?.categoryType;
    }
    if (widget.breadCrumbItems == null || widget.breadCrumbItems!.isEmpty) return null;
    final cat = widget.breadCrumbItems!.first;
    return cat.categoryType;
  }

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    AbstractField.fieldsData.clear();
    AbstractField.files.clear();

    if (widget.isEdit ?? false) {
      // حالة التعديل: تحميل البيانات من item
      item = getCloudData('edit_request') as ItemModel;
      clearCloudData("item_details");
      clearCloudData("with_more_details");
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
        categoryIds: item!.allCategoryIds!,
      );

      // تعبئة الحقول الأساسية
      adTitleControllers[defaultLangCode] = TextEditingController(
        text: item?.translatedName ?? "",
      );
      adSlugController.text = item?.slug ?? "";
      adDescriptionControllers[defaultLangCode] = TextEditingController(
        text: item?.translatedDescription ?? "",
      );

      if (item?.translations != null) {
        addCloudData("item_translations", item!.translations);
      }

      adPriceController.text = item?.price?.toString() ?? "";
      minSalaryController.text = item?.minSalary != null ? item!.minSalary.toString() : "";
      maxSalaryController.text = item?.maxSalary != null ? item!.maxSalary.toString() : "";
      phoneInputController.phoneNumber = item?.contact;
      phoneInputController.regionCode = item?.regionCode;
      adAdditionalDetailsController.text = item?.videoLink ?? "";
      titleImageURL = item?.image ?? "";
      List<String?>? list = item?.galleryImages?.map((e) => e.image).toList();
      mixedItemImageList.addAll([...list ?? []]);

      // تعبئة حقل المقايضة
      if (item?.swipTitle != null) {
        swapTargetController.text = item!.swipTitle!;
      }

      setState(() {});
    } else {
      // حالة الإضافة
      List<int> ids = widget.breadCrumbItems!.map((item) => item.id!).toList();
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
        categoryIds: ids.join(','),
      );
      selectedCategoryList = ids;
      final user = HiveUtils.getUserDetails();
      phoneInputController.phoneNumber = user.mobile;
      phoneInputController.phoneCode = user.countryCode;
      phoneInputController.regionCode = user.regionCode;

      adTitleControllers[HiveUtils.getLanguage()['code']] = TextEditingController();
    }

    _pickTitleImage.listener((p0) {
      titleImageURL = "";
      WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });
    });

    itemImagePicker.listener((images) {
      try {
        mixedItemImageList.addAll(List<dynamic>.from(images));
      } catch (e) {}
      setState(() {});
    });

    swapImagePicker.listener((images) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    swapTargetController.dispose();
    swapImagePicker.dispose();
    adSlugController.dispose();
    adPriceController.dispose();
    adAdditionalDetailsController.dispose();
    minSalaryController.dispose();
    maxSalaryController.dispose();
    _tabController?.dispose();
    _isValid.dispose();

    for (final controller in [
      ...adDescriptionControllers.values,
      ...adTitleControllers.values,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  String generateSlug(String title) {
    String slug = title.toLowerCase();
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    return slug;
  }

  bool isJobCategory() {
    if (widget.isEdit ?? false) {
      return item?.category?.isJobCategory == 1;
    }
    return widget.breadCrumbItems != null &&
        widget.breadCrumbItems!.isNotEmpty &&
        widget.breadCrumbItems![0].isJobCategory == 1;
  }

  bool isPriceOptional() {
    if (widget.isEdit ?? false) {
      return item?.category?.priceOptional == 1;
    }
    return widget.breadCrumbItems != null &&
        widget.breadCrumbItems!.isNotEmpty &&
        widget.breadCrumbItems![0].priceOptional == 1;
  }

  // بناء خريطة بيانات الإعلان (للوضعين: إضافة وتعديل)
  Map<String, dynamic> _buildItemDetailsMap() {
    // بناء خريطة الترجمات
    Map<String, Map<String, String>> translations = {};
    for (var lang in languages) {
      final langId = lang['id'].toString();
      final langCode = lang['code'];
      if (langCode == defaultLangCode) continue;

      final name = adTitleControllers[langCode]?.text.trim() ?? '';
      final description = adDescriptionControllers[langCode]?.text.trim() ?? '';

      final langTranslations = <String, String>{};
      if (name.isNotEmpty) langTranslations['name'] = name;
      if (description.isNotEmpty) langTranslations['description'] = description;

      if (langTranslations.isNotEmpty) {
        translations[langId] = langTranslations;
      }
    }

    final map = {
      "name": adTitleControllers[defaultLangCode]!.text,
      "slug": adSlugController.text,
      "description": adDescriptionControllers[defaultLangCode]!.text,
      if (widget.isEdit != true) "category_id": selectedCategoryList.last,
      if (widget.isEdit ?? false) "id": item?.id,
      "contact": phoneInputController.phoneNumber,
      "region_code": phoneInputController.regionCode,
      "video_link": adAdditionalDetailsController.text,
      if (widget.isEdit ?? false)
        "delete_item_image_id": deleteItemImageList.join(','),
      "all_category_ids": (widget.isEdit ?? false)
          ? item!.allCategoryIds
          : selectedCategoryList.join(','),
      "translations": json.encode(translations),
    };

    // معالجة السعر حسب نوع الفئة
    if (selectedCategoryType == 'donation') {
      map["price"] = "0";
    } else if (selectedCategoryType == 'swip') {
      map["price"] = "0";
    } else {
      map["price"] = adPriceController.text;
    }

    // إضافة حقول الوظائف إذا كانت الفئة وظيفة
    if (isJobCategory()) {
      map["min_salary"] = minSalaryController.text;
      map["max_salary"] = maxSalaryController.text;
    }

    // إضافة حقل المقايضة النصي
    if (selectedCategoryType == 'swip') {
      map["swip_title"] = swapTargetController.text;
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    languages = context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.language,
    ) as List? ??
        [];

    defaultLangCode = context.read<FetchSystemSettingsCubit>().getSetting(
      SystemSetting.defaultLanguage,
    );

    if (languages.isNotEmpty &&
        (languages[0]['code']?.toString().toLowerCase() ?? '') !=
            (defaultLangCode.toLowerCase())) {
      final defIndex = languages.indexWhere(
            (l) =>
        (l['code']?.toString().toLowerCase() ?? '') ==
            defaultLangCode.toLowerCase(),
      );
      if (defIndex > 0) {
        final defLang = languages.removeAt(defIndex);
        languages.insert(0, defLang);
      }
    }

    if (languages.isEmpty) {
      return Center(child: Text('No languages available'));
    }

    _tabController ??= TabController(
      length: languages.length,
      vsync: this,
      initialIndex: 0,
    );

    for (var lang in languages) {
      adTitleControllers[lang['code']] ??= TextEditingController();
      adDescriptionControllers[lang['code']] ??= TextEditingController();
    }

    // تعبئة الترجمات في حالة التعديل
    if ((widget.isEdit ?? false) && !_translationsPopulated) {
      if (item?.translations != null && (item!.translations as List).isNotEmpty) {
        for (var lang in languages) {
          final langCode = lang['code'];
          final langId = lang['id'];
          var translation = (item!.translations as List).firstWhere(
                (t) => t is Map<String, dynamic> && t['language_id'] == langId,
            orElse: () => null,
          );
          if (translation != null && translation is Map<String, dynamic>) {
            adTitleControllers[langCode]?.text =
                translation['name'] ?? (item?.translatedName ?? "");
            adDescriptionControllers[langCode]?.text =
                translation['description'] ?? (item?.translatedDescription ?? "");
          } else {
            adTitleControllers[langCode]?.text = item?.name ?? "";
            adDescriptionControllers[langCode]?.text = item?.description ?? "";
          }
        }
        _translationsPopulated = true;
      } else {
        for (var lang in languages) {
          final langCode = lang['code'];
          if (langCode == defaultLangCode) {
            adTitleControllers[langCode]?.text = item?.translatedName ?? "";
            adDescriptionControllers[langCode]?.text =
                item?.translatedDescription ?? "";
          } else {
            adTitleControllers[langCode]?.text = "";
            adDescriptionControllers[langCode]?.text = "";
          }
        }
        _translationsPopulated = true;
      }
    }

    String selectedLangCode = languages[selectedLangIndex]['code'];
    bool isDefault = selectedLangCode == defaultLangCode;

    return AnnotatedSafeArea(
      isAnnotated: true,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {},
        child: Scaffold(
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: "AdDetails".translate(context),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (languages.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: soldOutButtonColor,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _isValid,
                          builder: (context, value, child) {
                            return CustomText(
                              (value
                                  ? "allRequiredDefaultLangFilled"
                                  : "pleaseFillDefaultLangRequiredMsg")
                                  .translate(context),
                              color: soldOutButtonColor,
                              fontSize: context.font.normal,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                color: Colors.transparent,
                child: UiUtils.buildButton(
                  context,
                  outerPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  onPressed: () {
                    adSlugController.text = adSlugController.text.replaceAll(
                      RegExp(r'^-+|-+$'),
                      '',
                    );
                    _isValid.value = _formKey.currentState?.validate() ?? false;

                    if (_isValid.value) {
                      List<File>? galleryImages = mixedItemImageList
                          .where((element) => element != null && element is File)
                          .map((element) => element as File)
                          .toList();

                      // التحقق من الصورة الرئيسية
                      if (_pickTitleImage.pickedFile == null && titleImageURL == "") {
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "imageRequired".translate(context),
                            content: CustomText(
                              "selectImageYourItem".translate(context),
                            ),
                          ),
                        );
                        return;
                      }

                      // التحقق من صورة المقايضة (فقط في حالة الإضافة وليس التعديل)
                      // في التعديل، إذا لم يختر صورة جديدة، نستخدم الصورة القديمة
                      if (!(widget.isEdit ?? false) &&
                          selectedCategoryType == 'swip' &&
                          swapImagePicker.pickedFile == null) {
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            title: "imageRequired".translate(context),
                            content: CustomText("pleaseAddSwapItemImage".translate(context)),
                          ),
                        );
                        return;
                      }

                      // بناء بيانات الإعلان
                      final itemDetails = _buildItemDetailsMap();

                      // تخزين البيانات في CloudState
                      addCloudData("item_details", itemDetails);

                      // تخزين صورة المقايضة إذا تم اختيارها (جديدة)
                      if (selectedCategoryType == 'swip' && swapImagePicker.pickedFile != null) {
                        addCloudData("swip_image", swapImagePicker.pickedFile);
                      }

                      screenStack++;

                      if (context.read<FetchCustomFieldsCubit>().isEmpty()!) {
                        // لا توجد حقول مخصصة → ننتقل مباشرة لتحديد الموقع
                        addCloudData("with_more_details", itemDetails);
                        Navigator.pushNamed(
                          context,
                          Routes.confirmLocationScreen,
                          arguments: {
                            "isEdit": widget.isEdit,
                            "mainImage": _pickTitleImage.pickedFile,
                            "otherImage": galleryImages,
                            if (selectedCategoryType == 'swip')
                              "swipImage": swapImagePicker.pickedFile,
                          },
                        );
                      } else {
                        // توجد حقول مخصصة → ننتقل لشاشة الإضافية
                        Navigator.pushNamed(
                          context,
                          Routes.addMoreDetailsScreen,
                          arguments: {
                            "context": context,
                            "isEdit": widget.isEdit == true,
                            "mainImage": _pickTitleImage.pickedFile,
                            "otherImage": galleryImages,
                            if (selectedCategoryType == 'swip')
                              "swipImage": swapImagePicker.pickedFile,
                          },
                        ).then((value) {
                          screenStack--;
                        });
                      }
                    }
                  },
                  height: 48,
                  fontSize: context.font.large,
                  buttonTitle: "next".translate(context),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (languages.length > 1)
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: context.color.territoryColor,
                      unselectedLabelColor:
                      context.color.textColorDark.withValues(alpha: 0.5),
                      indicatorColor: context.color.territoryColor,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabAlignment: TabAlignment.start,
                      onTap: (index) {
                        if (selectedLangIndex == index) {
                          _isValid.value = _formKey.currentState?.validate() ?? true;
                          return;
                        }
                        if (selectedLangIndex == 0 && index != 0) {
                          _isValid.value = _formKey.currentState?.validate() ?? false;
                          if (!_isValid.value) {
                            _tabController?.animateTo(selectedLangIndex);
                            return;
                          }
                        }
                        setState(() {
                          selectedLangIndex = index;
                          _formKey.currentState?.reset();
                        });
                      },
                      tabs: languages.map((lang) {
                        final isDef = lang['code'] == defaultLangCode;
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Text(lang['name']),
                              ValueListenableBuilder(
                                valueListenable: _isValid,
                                builder: (context, value, child) {
                                  return value && isDef
                                      ? child!
                                      : const SizedBox.shrink();
                                },
                                child: Icon(
                                  Icons.check_box_rounded,
                                  color: context.color.territoryColor,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 18),
                  CustomText(
                    "youAreAlmostThere".translate(context),
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w600,
                    color: context.color.textColorDark,
                  ),
                  const SizedBox(height: 16),
                  if (widget.breadCrumbItems != null)
                    SizedBox(
                      height: 20,
                      width: context.screenWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.breadCrumbItems!.length,
                          itemBuilder: (context, index) {
                            bool isNotLast =
                                (widget.breadCrumbItems!.length - 1) != index;
                            return Row(
                              children: [
                                InkWell(
                                  onTap: () => _onBreadCrumbItemTap(index),
                                  child: CustomText(
                                    widget.breadCrumbItems![index].name!,
                                    color: isNotLast
                                        ? context.color.textColorDark
                                        : context.color.territoryColor,
                                    firstUpperCaseWidget: true,
                                  ),
                                ),
                                if (index < widget.breadCrumbItems!.length - 1)
                                  CustomText(
                                    " > ",
                                    color: context.color.territoryColor,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),

                  // العنوان
                  CustomText(
                    isDefault
                        ? "adTitle".translate(context)
                        : "${'adTitle'.translate(context)} (${languages[selectedLangIndex]['name']})",
                  ),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adTitleControllers[selectedLangCode],
                    validator: isDefault ? CustomTextFieldValidator.nullCheck : null,
                    onChange: (value) {
                      adSlugController.text = generateSlug(value);
                    },
                    action: TextInputAction.next,
                    capitalization: TextCapitalization.sentences,
                    hintText: isDefault
                        ? "adTitleHere".translate(context)
                        : "${'adTitleHere'.translate(context)} (${languages[selectedLangIndex]['name']})",
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      fontSize: context.font.normal,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // الوصف
                  CustomText(
                    isDefault
                        ? "descriptionLbl".translate(context)
                        : "${'descriptionLbl'.translate(context)} (${languages[selectedLangIndex]['name']})",
                  ),
                  const SizedBox(height: 15),
                  CustomTextFormField(
                    controller: adDescriptionControllers[selectedLangCode],
                    validator: isDefault ? CustomTextFieldValidator.nullCheck : null,
                    action: TextInputAction.newline,
                    capitalization: TextCapitalization.sentences,
                    hintText: isDefault
                        ? "writeSomething".translate(context)
                        : "${'writeSomething'.translate(context)} (${languages[selectedLangIndex]['name']})",
                    maxLine: 100,
                    minLine: 6,
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      fontSize: context.font.normal,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // الصورة الرئيسية
                  Row(
                    children: [
                      CustomText("mainPicture".translate(context)),
                      const SizedBox(width: 3),
                      CustomText(
                        "maxSize".translate(context),
                        fontStyle: FontStyle.italic,
                        fontSize: context.font.small,
                      ),
                    ],
                  ),
                  CustomText(
                    "recommendedSize".translate(context),
                    fontStyle: FontStyle.italic,
                    fontSize: context.font.small,
                    color: context.color.textLightColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(children: [...[], titleImageListener()]),
                  const SizedBox(height: 10),

                  // باقي الصور
                  Row(
                    spacing: 3,
                    children: [
                      CustomText("otherPictures".translate(context)),
                      CustomText(
                        "max5Images".translate(context),
                        fontStyle: FontStyle.italic,
                        fontSize: context.font.small,
                      ),
                    ],
                  ),
                  CustomText(
                    "recommendedSize".translate(context),
                    fontStyle: FontStyle.italic,
                    fontSize: context.font.small,
                    color: context.color.textLightColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 10),
                  itemImagesListener(),
                  const SizedBox(height: 10),

                  // حقول التبرع (عرض مجاني فقط)
                  if (selectedCategoryType == 'donation') ...[
                    Row(
                      children: [
                        CustomText("${"price".translate(context)}: "),
                        CustomText(
                          "free".translate(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ] else if (selectedCategoryType == 'swip') ...[
                    // حقول المقايضة
                    CustomText("What is he swapping for ?".translate(context)),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: swapTargetController,
                      validator: CustomTextFieldValidator.nullCheck,
                      hintText: "Example: iPhone 13 for a gaming laptop".translate(context),
                      maxLine: 3,
                    ),
                    const SizedBox(height: 15),
                    CustomText("Image of the item to swap".translate(context)),
                    const SizedBox(height: 8),
                    _buildSwapImagePicker(),
                  ] else ...[
                    // الحالة العادية: عرض السعر أو الوظائف
                    CustomText(
                      isJobCategory()
                          ? "salary".translate(context)
                          : "price".translate(context),
                    ),
                    const SizedBox(height: 10),
                    isJobCategory()
                        ? buildSalaryRange()
                        : CustomTextFormField(
                      controller: adPriceController,
                      action: TextInputAction.next,
                      fixedPrefix: ConstrainedBox(
                        constraints: BoxConstraints.tight(Size(24, 24)),
                        child: Center(
                          child: CustomText(
                            Constant.currencySymbol,
                            fontSize: context.font.large,
                            color: context.color.textDefaultColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      formaters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+')),
                      ],
                      keyboard: TextInputType.number,
                      validator: isPriceOptional()
                          ? null
                          : CustomTextFieldValidator.nullCheck,
                      hintText: "0",
                      hintTextStyle: TextStyle(
                        color: context.color.textDefaultColor.withValues(alpha: 0.5),
                        fontSize: context.font.normal,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  CustomText("phoneNumber".translate(context)),
                  const SizedBox(height: 10),
                  PhoneInput(controller: phoneInputController),
                  const SizedBox(height: 10),
                  CustomText("videoLink".translate(context)),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adAdditionalDetailsController,
                    validator: CustomTextFieldValidator.url,
                    hintText: "videoUrlAddHint".translate(context),
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      fontSize: context.font.normal,
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomText(
                    "${"adSlug".translate(context)}\t(${"englishOnlyLbl".translate(context)})",
                  ),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: adSlugController,
                    formaters: [SlugFormatter()],
                    validator: CustomTextFieldValidator.slug,
                    action: TextInputAction.next,
                    hintText: "adSlugHere".translate(context),
                    hintTextStyle: TextStyle(
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      fontSize: context.font.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onBreadCrumbItemTap(int index) {
    int popTimes = (widget.breadCrumbItems!.length - 1) - index;
    int current = index;
    int length = widget.breadCrumbItems!.length;

    for (int i = length - 1; i >= current + 1; i--) {
      widget.breadCrumbItems!.removeAt(i);
    }

    for (int i = 0; i < popTimes; i++) {
      Navigator.pop(context);
    }
    setState(() {});
  }

  Future<void> showImageSourceDialog(
      BuildContext context,
      Function(ImageSource) onSelected,
      ) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText('selectImageSource'.translate(context)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: CustomText('camera'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.camera);
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: CustomText('gallery'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, List<File>? files) {
      Widget currentWidget = Container();
      File? file = files?.isNotEmpty == true ? files![0] : null;

      if (titleImageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(titleImageURL),
            );
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: UiUtils.getImage(titleImageURL, fit: BoxFit.cover),
          ),
        );
      }

      if (file != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(5),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ],
          ),
        );
      }

      return Wrap(
        children: [
          if (file == null && titleImageURL.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    _pickTitleImage.resumeSubscription();
                    _pickTitleImage.pick(
                      pickMultiple: false,
                      context: context,
                      source: source,
                    );
                    _pickTitleImage.pauseSubscription();
                    titleImageURL = "";
                    setState(() {});
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addMainPicture".translate(context),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              closeButton(context, () {
                _pickTitleImage.clearImage();
                titleImageURL = "";
                setState(() {});
              }),
            ],
          ),
          if (file != null || titleImageURL.isNotEmpty)
            uploadPhotoCard(
              context,
              onTap: () {
                showImageSourceDialog(context, (source) {
                  _pickTitleImage.resumeSubscription();
                  _pickTitleImage.pick(
                    pickMultiple: false,
                    context: context,
                    source: source,
                  );
                  _pickTitleImage.pauseSubscription();
                  titleImageURL = "";
                  setState(() {});
                });
              },
            ),
        ],
      );
    });
  }

  Widget itemImagesListener() {
    return itemImagePicker.listenChangesInUI((context, files) {
      Widget current = Container();

      current = Wrap(
        children: List.generate(mixedItemImageList.length, (index) {
          final image = mixedItemImageList[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  HelperUtils.unfocus();
                  if (image is String) {
                    UiUtils.showFullScreenImage(
                      context,
                      provider: NetworkImage(image),
                    );
                  } else {
                    UiUtils.showFullScreenImage(
                      context,
                      provider: FileImage(image),
                    );
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(5),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ImageAdapter(image: image),
                ),
              ),
              closeButton(context, () {
                if (image is String) {
                  final matchingIndex = item!.galleryImages!.indexWhere(
                        (galleryImage) => galleryImage.image == image,
                  );

                  if (matchingIndex != -1) {
                    deleteItemImageList.add(
                      item!.galleryImages![matchingIndex].id!,
                    );
                    setState(() {});
                  }
                }

                mixedItemImageList.removeAt(index);
                setState(() {});
              }),
            ],
          );
        }),
      );

      return Wrap(
        runAlignment: WrapAlignment.start,
        children: [
          if ((files == null || files.isEmpty) && mixedItemImageList.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    itemImagePicker.pick(
                      pickMultiple: source == ImageSource.gallery,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: source,
                    );
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addOtherPicture".translate(context),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.normal,
                  ),
                ),
              ),
            ),
          current,
          if (mixedItemImageList.length < 5)
            if (files != null && files.isNotEmpty || mixedItemImageList.isNotEmpty)
              uploadPhotoCard(
                context,
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    itemImagePicker.pick(
                      pickMultiple: source == ImageSource.gallery,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: source,
                    );
                  });
                },
              ),
        ],
      );
    });
  }

  Widget closeButton(BuildContext context, Function onTap) {
    return PositionedDirectional(
      top: 6,
      end: 6,
      child: GestureDetector(
        onTap: () {
          onTap.call();
        },
        child: Container(
          decoration: BoxDecoration(
            color: context.color.primaryColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.close,
              size: 24,
              color: context.color.textDefaultColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: DottedBorder(
          color: context.color.textColorDark.withValues(alpha: 0.5),
          borderType: BorderType.RRect,
          radius: const Radius.circular(10),
          child: Container(
            alignment: AlignmentDirectional.center,
            child: CustomText("uploadPhoto".translate(context)),
          ),
        ),
      ),
    );
  }

  Widget buildSalaryRange() {
    String? rangeChecker() {
      final min = int.tryParse(minSalaryController.text);
      final max = int.tryParse(maxSalaryController.text);

      if (min == null || max == null) return null;

      if (min < max) {
        return null;
      } else {
        return "invalidRange".translate(context);
      }
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: CustomTextFormField(
            controller: minSalaryController,
            action: TextInputAction.next,
            fixedPrefix: ConstrainedBox(
              constraints: BoxConstraints.tight(Size(24, 24)),
              child: Center(
                child: CustomText(
                  Constant.currencySymbol,
                  fontSize: context.font.large,
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            formaters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+'))],
            validatorFunction: (value) => rangeChecker(),
            keyboard: TextInputType.number,
            hintText: "minLbl".translate(context),
            hintTextStyle: TextStyle(
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
              fontSize: context.font.normal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomTextFormField(
            controller: maxSalaryController,
            action: TextInputAction.next,
            fixedPrefix: ConstrainedBox(
              constraints: BoxConstraints.tight(Size(24, 24)),
              child: Center(
                child: CustomText(
                  Constant.currencySymbol,
                  fontSize: context.font.large,
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            validatorFunction: (value) => rangeChecker(),
            formaters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+'))],
            keyboard: TextInputType.number,
            hintText: "maxLbl".translate(context),
            hintTextStyle: TextStyle(
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
              fontSize: context.font.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwapImagePicker() {
    return swapImagePicker.listenChangesInUI((context, files) {
      File? file = files?.isNotEmpty == true ? files![0] : null;
      return GestureDetector(
        onTap: () {
          showImageSourceDialog(context, (source) {
            swapImagePicker.pick(
              pickMultiple: false,
              context: context,
              source: source,
            );
          });
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: context.color.textLightColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: file != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(file, fit: BoxFit.cover),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: context.color.textLightColor),
              const SizedBox(height: 8),
              CustomText("Add image".translate(context), fontSize: context.font.small),
            ],
          ),
        ),
      );
    });
  }
}