// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/chat/delete_message_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/load_chat_messages.dart';
import 'package:eClassify/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:eClassify/data/cubits/chat/send_message.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:eClassify/data/cubits/item/change_my_items_status_cubit.dart';
import 'package:eClassify/data/cubits/item/create_featured_ad_cubit.dart';
import 'package:eClassify/data/cubits/item/delete_item_cubit.dart';
import 'package:eClassify/data/cubits/item/fetch_item_cubit.dart';
import 'package:eClassify/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:eClassify/data/cubits/item/item_total_click_cubit.dart';
import 'package:eClassify/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:eClassify/data/cubits/item/related_item_cubit.dart';
import 'package:eClassify/data/cubits/location/leaf_location_cubit.dart';
import 'package:eClassify/data/cubits/renew_item_cubit.dart';
import 'package:eClassify/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:eClassify/data/cubits/report/item_report_cubit.dart';
import 'package:eClassify/data/cubits/report/update_report_items_list_cubit.dart';
import 'package:eClassify/data/cubits/safety_tips_cubit.dart';
import 'package:eClassify/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_ads_listing_subscription_packages_cubit.dart';
import 'package:eClassify/data/cubits/subscription/fetch_user_package_limit_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/model/item/job_application.dart'
    show JobApplication;
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/model/report_item/reason_model.dart';
import 'package:eClassify/data/model/safety_tips_model.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/ad_banner_screen.dart';
import 'package:eClassify/ui/screens/chat/chat_screen.dart';
import 'package:eClassify/ui/screens/google_map_screen.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:eClassify/ui/screens/home/widgets/item_card_widget.dart';
import 'package:eClassify/ui/screens/item/my_item_tab_screen.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/location_map/location_map_controller.dart';
import 'package:eClassify/ui/screens/widgets/location_map/location_map_widget.dart';
import 'package:eClassify/ui/screens/widgets/package_select_bottom_sheet.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/screens/widgets/video_view_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/cloud_state/cloud_state.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/validator.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AdDetailsScreen extends StatefulWidget {
  const AdDetailsScreen({
    super.key,
    this.model,
    this.slug,
    this.itemId,
    this.tabStatus,
  });
  final ItemModel? model;
  final String? slug;
  final int? itemId;
  final String? tabStatus;

  @override
  AdDetailsScreenState createState() => AdDetailsScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => FetchMyItemsCubit()),
          BlocProvider(create: (context) => CreateFeaturedAdCubit()),
          BlocProvider(create: (context) => FetchItemReportReasonsListCubit()),
          BlocProvider(create: (context) => ItemReportCubit()),
          BlocProvider(create: (context) => MakeAnOfferItemCubit()),
          BlocProvider(create: (context) => FetchItemCubit()),
        ],
        child: AdDetailsScreen(
          model: arguments?['model'],
          slug: arguments?['slug'],
          itemId: arguments?['item_id'],
          tabStatus: arguments?['status_tab'],
        ),
      ),
    );
  }
}

class AdDetailsScreenState extends CloudState<AdDetailsScreen> {
  int currentPage = 0;
  bool? isFeaturedLimit;
  List<String> selectedFeaturedAdsOptions = [];

  bool isShowReportAds = true;
  final PageController pageController = PageController();
  final List<String?> images = [];
  late final ScrollController _pageScrollController = ScrollController();
  List<ReportReason>? reasons = [];
  late int selectedId;
  final TextEditingController _reportMessageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _makeAnOfferMessageController = TextEditingController();
  final GlobalKey<FormState> _offerFormKey = GlobalKey();

  late final settings = context.read<FetchSystemSettingsCubit>().getSetting(SystemSetting.allSettings);
  late ItemModel model;

  late bool isAddedByMe;
  bool isFeaturedWidget = true;
  String youtubeVideoThumbnail = "";
  int? categoryId;
  FlickManager? flickManager;
  late LocationMapController? _locationController;
  bool isAdminEditedReasonExpanded = false;

  late final LeafLocation? location;

  // --- Payment related variables ---
  double? platformPrice;
  bool _isProcessingPayment = false;
  final Map<int, bool> _paymentStatusCache = {};

  @override
  void initState() {
    super.initState();
    _fetchPlatformPrice();
    location = context.read<LeafLocationCubit>().state;
    if (widget.model != null) {
      initVariables(widget.model!);
    }
    pageController.addListener(() {
      setState(() {
        currentPage = pageController.page!.round();
      });
    });
    _pageScrollController.addListener(_pageScroll);
  }

  Future<void> _fetchPlatformPrice() async {
    try {
      final settings = context.read<FetchSystemSettingsCubit>().getRawSettings();
      platformPrice = double.tryParse(settings['platform_price']?.toString() ?? '1');
    } catch (e) {
      platformPrice = 1.0;
    }
  }

  Future<bool> _checkPaymentStatus() async {
    if (model.id == null) return false;

    // إذا كانت البيانات مخزنة مسبقاً في الذاكرة، نرجعها مباشرة
    if (_paymentStatusCache.containsKey(model.id)) {
      return _paymentStatusCache[model.id]!;
    }

    try {
      // استدعاء الـ API حسب الرابط الذي أرفقته
      final response = await Api.get(
        url: 'check-payment-status',
        queryParameters: {'pub_id': model.id},
      );

      // التحقق من الحقل is_paid في الاستجابة
      final isPaid = response['is_paid'] == true;

      // تخزين النتيجة في الكاش
      _paymentStatusCache[model.id!] = isPaid;

      return isPaid;
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return false;
    }
  }

  Future<void> _showPaymentDialog() async {
    if (_isProcessingPayment) return;
    _isProcessingPayment = true;

    Map<String, dynamic>? bankTransferDetails;
    try {
      final paymentSettings = await Api.get(url: 'get-payment-settings');
      bankTransferDetails = paymentSettings['data']['bankTransfer'];
    } catch (e) {
      // ignore
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText('دفع لعرض التواصل'.translate(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'تحتاج إلى دفع ${platformPrice?.toStringAsFixed(2) ?? '1'} دولار لعرض رقم البائع أو بدء المحادثة.',
            ),
            if (bankTransferDetails != null) ...[
              const SizedBox(height: 10),
              CustomText('تعليمات التحويل البنكي:', fontWeight: FontWeight.bold),
              CustomText('اسم البنك: ${bankTransferDetails['bank_name']}'),
              CustomText('اسم الحساب: ${bankTransferDetails['account_holder_name']}'),
              CustomText('رقم الحساب: ${bankTransferDetails['account_number']}'),
              if (bankTransferDetails['ifsc_swift_code'] != null)
                CustomText('رمز Swift: ${bankTransferDetails['ifsc_swift_code']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: CustomText('إلغاء'.translate(context)),
          ),
          ElevatedButton(
            onPressed: () => _processPayment(ctx),
            child: CustomText('دفع الآن'.translate(context)),
          ),
        ],
      ),
    ).then((_) {
      _isProcessingPayment = false;
    });
  }

  Future<void> _processPayment(BuildContext dialogContext) async {
    if (model.id == null) return;
    try {
      LoadingWidgets.showLoader(context);
      final response = await Api.post(
        url: 'payment-intent',
        parameter: {
          'pub_id': model.id,
          'payment_method': 'bankTransfer',
          'platform_type': Platform.isAndroid ? 'android' : 'ios',
        },
      );

      Navigator.pop(context); // close loading

      if (response['error'] == false) {
        _paymentStatusCache[model.id!] = true;
        _isProcessingPayment = false;
        Navigator.pop(dialogContext); // close payment dialog
        HelperUtils.showSnackBarMessage(
          context,
          'تم إنشاء طلب الدفع بنجاح. سيتم تفعيل التواصل بعد تأكيد الدفع.',
        );
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      _isProcessingPayment = false;
      HelperUtils.showSnackBarMessage(context, 'فشلت عملية الدفع. حاول مرة أخرى.');
    }
  }

  void _showPhoneNumber() {
    if (model.contact == null || model.contact!.isEmpty) {
      HelperUtils.showSnackBarMessage(context, 'رقم الهاتف غير متوفر.');
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: CustomText('رقم التواصل'.translate(context)),
        content: CustomText(model.contact!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: CustomText('إغلاق'.translate(context)),
          ),
          ElevatedButton(
            onPressed: () {
              HelperUtils.launchPathURL(
                isTelephone: false,
                isSMS: true,
                isMail: false,
                value: formatPhoneNumber(
                  model.contact ?? model.user!.mobile!,
                  Constant.defaultCountryCode,
                ),
                context: context,
              );
            },
            child: CustomText('اتصال'.translate(context)),
          ),
        ],
      ),
    );
  }

  void _openChat() async {
    if (model.id == null) return;

    final isPaid = await _checkPaymentStatus();
    if (!isPaid) {
      _showPaymentDialog();
      return;
    }

    final chatedUser = context.select(
          (GetBuyerChatListCubit cubit) => cubit.getOfferForItem(model.id!),
    );

    if (chatedUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => SendMessageCubit()),
              BlocProvider(create: (context) => LoadChatMessagesCubit()),
              BlocProvider(create: (context) => DeleteMessageCubit()),
            ],
            child: ChatScreen(
              itemId: chatedUser.itemId.toString(),
              profilePicture: chatedUser.seller?.profile ?? "",
              userName: chatedUser.seller?.name ?? "",
              date: chatedUser.createdAt!,
              itemOfferId: chatedUser.id!,
              itemPrice: chatedUser.item?.price?.toString(),
              itemOfferPrice: chatedUser.amount,
              itemImage: chatedUser.item?.image ?? "",
              itemTitle: chatedUser.item?.name?.localized ?? "",
              userId: chatedUser.sellerId.toString(),
              buyerId: chatedUser.buyerId.toString(),
              status: chatedUser.item!.status,
              from: "item",
              isPurchased: model.isPurchased!,
              alreadyReview: model.review?.isEmpty ?? true ? false : true,
              isFromBuyerList: true,
            ),
          ),
        ),
      );
    } else {
      context.read<MakeAnOfferItemCubit>().makeAnOfferItem(
        id: model.id!,
        from: "chat",
      );
    }
  }

  void _navigateToChat() {
    _openChat(); // Same as open chat
  }

  void initVariables(ItemModel itemModel) {
    model = itemModel;

    isAddedByMe =
        (model.user?.id != null ? model.user!.id.toString() : model.userId) ==
            HiveUtils.getUserId();

    if (isAddedByMe) {
      context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
    } else {
      context.read<FetchItemReportReasonsListCubit>().fetch();
      context.read<FetchSafetyTipsListCubit>().fetchSafetyTips();
      context.read<FetchSellerRatingsCubit>().fetch(
        sellerId: (model.user?.id != null ? model.user!.id! : model.userId!),
      );
    }
    categoryId = model.category != null ? model.category?.id : model.categoryId;

    setItemClick();
    combineImages();
    context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
      categoryId: categoryId!,
      location: location,
    );
    _pageScrollController.addListener(_pageScroll);
    if (model.longitude != null && model.latitude != null) {
      _locationController = LocationMapController(
        initialCoordinates: LatLng(model.latitude!, model.longitude!),
      );
    } else {
      _locationController = null;
    }
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchRelatedItemsCubit>().hasMoreData()) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItemsMore(
          categoryId: categoryId!,
          location: location,
        );
      }
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    _pageScrollController.dispose();
    _makeAnOfferMessageController.dispose();
    _reportMessageController.dispose();
    super.dispose();
  }

  void combineImages() {
    images.add(model.image);
    if (model.galleryImages != null && model.galleryImages!.isNotEmpty) {
      for (var element in model.galleryImages!) {
        images.add(element.image);
      }
    }

    // Add swap image if exists
    if (model.category?.categoryType == 'swip' && model.swipImage != null) {
      images.add(model.swipImage);
    }

    if (model.videoLink != null && model.videoLink!.trim().isNotEmpty) {
      images.add(model.videoLink);

      if (HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
        String? videoId = YoutubePlayer.convertUrlToId(model.videoLink!);
        if (videoId != null) {
          youtubeVideoThumbnail = YoutubePlayer.getThumbnail(videoId: videoId);
        }
      } else {
        flickManager = FlickManager(
          videoPlayerController: VideoPlayerController.networkUrl(
            Uri.parse(model.videoLink!),
          ),
        );
        flickManager?.onVideoEnd = () {};
      }
    }
  }

  Widget _buildTypeIndicator(BuildContext context) {
    String? type = model.category?.categoryType;

    if (type == 'donation') {
      return Row(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 20),
          const SizedBox(width: 4),
          CustomText(
            'free'.translate(context),
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: context.font.large,
          ),
        ],
      );
    } else if (type == 'swip') {
      return Row(
        children: [
          Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: CustomText(
              'Wants to swap for: ${model.swipTitle ?? ''}',
              fontSize: context.font.large,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return UiUtils.getPriceWidget(model, context);
    }
  }

  void setItemClick() {
    if (!isAddedByMe) {
      context.read<ItemTotalClickCubit>().itemTotalClick(model.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedSafeArea(
      statusBarColor: context.color.secondaryDetailsColor,
      isAnnotated: true,
      child: BlocConsumer<FetchItemCubit, FetchItemState>(
        listener: (context, state) {
          if (state is FetchItemSuccess) {
            log('success');
            initVariables(state.item);
          }
        },
        builder: (context, state) {
          if (state is FetchItemInitial &&
              (widget.slug != null || widget.itemId != null)) {
            context.read<FetchItemCubit>().fetchItem(
              itemId: widget.itemId,
              slug: widget.slug,
            );
            return Center(child: UiUtils.progress());
          } else if (state is FetchItemLoading) {
            return Center(child: UiUtils.progress());
          } else if (state is FetchItemFailure) {
            return SomethingWentWrong();
          }
          return MultiBlocListener(
            listeners: [
              BlocListener<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                listener: (context, state) {
                  if (state is MakeAnOfferItemInProgress) {
                    LoadingWidgets.showLoader(context);
                  }
                  if (state is MakeAnOfferItemSuccess ||
                      state is MakeAnOfferItemFailure) {
                    LoadingWidgets.hideLoader(context);
                  }
                },
              ),
              BlocListener<RenewItemCubit, RenewItemState>(
                listener: (context, changeState) {
                  if (changeState is RenewItemInProgress) {
                    LoadingWidgets.showLoader(context);
                  }
                  if (changeState is RenewItemInSuccess) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      changeState.responseMessage,
                    );
                    context.read<FetchItemCubit>().fetchItem(slug: model.slug);
                    myAdsCubitReference[widget.tabStatus]?.fetchMyItems(
                      getItemsWithStatus: widget.tabStatus,
                    );
                    LoadingWidgets.hideLoader(context);
                  } else if (changeState is RenewItemFailure) {
                    LoadingWidgets.hideLoader(context);
                    HelperUtils.showSnackBarMessage(context, changeState.error);
                  }
                },
              ),
            ],
            child: Scaffold(
              appBar: UiUtils.buildAppBar(
                context,
                backgroundColor: context.color.secondaryDetailsColor,
                showBackButton: true,
                actions: _buildAppBarActions(),
              ),
              backgroundColor: context.color.secondaryDetailsColor,
              bottomNavigationBar: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 10,
                  end: 10,
                  top: 5,
                  bottom: 10,
                ),
                child: bottomButtonWidget(),
              ),
              body: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(13.0, 0.0, 13.0, 13.0),
                children: <Widget>[
                  setImageViewer(),
                  if (isAddedByMe) setLikesAndViewsCount(),
                  if (model.isEditedByAdmin == 1 &&
                      model.translatedAdminEditReason != null &&
                      isAddedByMe) ...[
                    const SizedBox(height: 20),
                    adminEditedReason(),
                    const SizedBox(height: 5),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: CustomText(
                            model.translatedName!,
                            color: context.color.textDefaultColor,
                            fontSize: context.font.large,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (model.category?.isJobCategory == 1 && isAddedByMe) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: UiUtils.buildButton(
                              context,
                              disabled: model.status == 'sold out',
                              onTapDisabledButton: () {
                                HelperUtils.showSnackBarMessage(
                                  context,
                                  'jobIsClosed'.translate(context),
                                );
                              },
                              onPressed: () => Navigator.of(context).pushNamed(
                                Routes.jobApplicationList,
                                arguments: {"itemId": model.id},
                              ),
                              height: 30,
                              buttonTitle: 'jobApplications'.translate(context),
                              fontSize: context.font.small,
                              buttonColor: context.color.territoryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  setPriceAndStatus(),
                  if (isAddedByMe) setRejectedReason(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (model.translatedAddress != null)
                        Expanded(child: setAddress()),
                      CustomText(
                        model.created!.formatDate(format: "d MMM yyyy"),
                        maxLines: 1,
                        color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (Constant.isGoogleBannerAdsEnabled == "1") ...[
                    AdBannerWidget(),
                  ],
                  const SizedBox(height: 10),
                  if (isAddedByMe && !model.isFeature!) createFeaturesAds(),
                  if (model.allTranslatedCustomFields?.isNotEmpty ?? false)
                    customFields(),
                  const Divider(
                    thickness: 1,
                    color: Color(0x1A000000),
                  ),
                  setDescription(),

                  // Swap info
                  if (model.category?.categoryType == 'swip' && model.swipTitle != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, color: Colors.blue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    'ماذا يريد في المقابل؟',
                                    fontSize: context.font.small,
                                    color: context.color.textLightColor,
                                  ),
                                  CustomText(
                                    model.swipTitle!,
                                    fontSize: context.font.large,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Divider(
                    thickness: 1,
                    color: Color(0x1A000000),
                  ),
                  if (!isAddedByMe && model.user != null) setSellerDetails(),
                  setLocation(),
                  if (Constant.isGoogleBannerAdsEnabled == "1") ...[
                    const Divider(
                      thickness: 1,
                      color: Color(0x1A000000),
                    ),
                    AdBannerWidget(margin: EdgeInsets.only(top: 10)),
                  ],
                  if (!isAddedByMe) reportedAdsWidget(),
                  if (!isAddedByMe) relatedAds(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    List<Widget> actions = [];
    if (isAddedByMe && (model.status == Constant.statusActive || model.status == Constant.statusApproved)) {
      actions.add(
        Padding(
          padding: EdgeInsetsDirectional.only(
            end: isAddedByMe &&
                (model.status != Constant.statusSoldOut &&
                    model.status != Constant.statusReview &&
                    model.status != Constant.statusResubmitted &&
                    model.status != Constant.statusInactive &&
                    model.status != Constant.statusPermanentRejected &&
                    model.status != Constant.statusSoftRejected)
                ? 30.0
                : 15,
          ),
          child: IconButton(
            onPressed: () {
              HelperUtils.shareItem(context, "ad-details", model.slug!);
            },
            icon: Icon(
              Icons.share,
              size: 24,
              color: context.color.textDefaultColor,
            ),
          ),
        ),
      );
    }
    if (isAddedByMe &&
        (model.status != Constant.statusSoldOut &&
            model.status != Constant.statusReview &&
            model.status != Constant.statusResubmitted &&
            model.status != Constant.statusInactive &&
            model.status != Constant.statusPermanentRejected) &&
        model.status != Constant.statusExpired) {
      actions.add(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => DeleteItemCubit()),
            BlocProvider(create: (context) => ChangeMyItemStatusCubit()),
          ],
          child: Builder(
            builder: (context) {
              return BlocListener<DeleteItemCubit, DeleteItemState>(
                listener: (context, deleteState) {
                  if (deleteState is DeleteItemSuccess) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      "deleteItemSuccessMsg".translate(context),
                    );
                    context.read<FetchMyItemsCubit>().deleteItem(model);
                    Navigator.pop(context, "refresh");
                  } else if (deleteState is DeleteItemFailure) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      deleteState.errorMessage,
                    );
                  }
                },
                child: BlocListener<ChangeMyItemStatusCubit, ChangeMyItemStatusState>(
                  listener: (context, changeState) {
                    if (changeState is ChangeMyItemStatusSuccess) {
                      HelperUtils.showSnackBarMessage(
                        context,
                        "adsStatusUpdatedSuccessfully".translate(context),
                      );
                      Navigator.pop(context, "refresh");
                    } else if (changeState is ChangeMyItemStatusFailure) {
                      HelperUtils.showSnackBarMessage(
                        context,
                        changeState.errorMessage,
                      );
                    }
                  },
                  child: Container(
                    height: 24,
                    width: 24,
                    margin: const EdgeInsetsDirectional.only(end: 30.0),
                    alignment: AlignmentDirectional.center,
                    child: PopupMenuButton(
                      color: context.color.territoryColor,
                      offset: const Offset(-12, 15),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(17),
                          bottomRight: Radius.circular(17),
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(0),
                        ),
                      ),
                      child: SvgPicture.asset(
                        AppIcons.more,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          context.color.textDefaultColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      itemBuilder: (context) => [
                        if (model.status == Constant.statusActive ||
                            model.status == Constant.statusApproved)
                          PopupMenuItem(
                            onTap: () {
                              Future.delayed(Duration.zero, () {
                                context
                                    .read<ChangeMyItemStatusCubit>()
                                    .changeMyItemStatus(
                                  id: model.id!,
                                  status: Constant.statusInactive,
                                );
                              });
                            },
                            child: CustomText(
                              "deactivate".translate(context),
                              color: context.color.buttonColor,
                            ),
                          ),
                        if (model.status == Constant.statusActive ||
                            model.status == Constant.statusApproved ||
                            model.status == Constant.statusSoftRejected)
                          PopupMenuItem(
                            child: CustomText(
                              "lblremove".translate(context),
                              color: context.color.buttonColor,
                            ),
                            onTap: () async {
                              var delete = await UiUtils.showBlurredDialoge(
                                context,
                                dialoge: BlurredDialogBox(
                                  title: "deleteBtnLbl".translate(context),
                                  content: CustomText(
                                    "deleteitemwarning".translate(context),
                                  ),
                                ),
                              );
                              if (delete == true) {
                                Future.delayed(Duration.zero, () {
                                  context
                                      .read<DeleteItemCubit>()
                                      .deleteItem(id: model.id!);
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    return actions;
  }

  Widget bottomButtonWidget() {
    if (isAddedByMe) {
      final contextColor = context.color;

      return Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditBtnVisible())
            Expanded(
              child: _buildButton(
                "editBtnLbl".translate(context),
                    () {
                  addCloudData("edit_request", model);
                  addCloudData("edit_from", model.status);
                  Navigator.pushNamed(
                    context,
                    Routes.addItemDetails,
                    arguments: {"isEdit": true},
                  );
                },
                contextColor.secondaryColor,
                contextColor.territoryColor,
              ),
            ),
          if (model.status == Constant.statusExpired)
            Expanded(
              child: _buildButton(
                "renew".translate(context),
                    () {
                  final isFreeAdListingEnabled =
                      context.read<FetchSystemSettingsCubit>().getSetting(
                        SystemSetting.freeAdListing,
                      ) ==
                          "1";
                  if (isFreeAdListingEnabled) {
                    context.read<RenewItemCubit>().renewItem(itemId: model.id!);
                  } else {
                    PackageSelectBottomSheet.show(context, (packageId) {
                      Future.delayed(Duration.zero, () {
                        context.read<RenewItemCubit>().renewItem(
                          packageId: packageId,
                          itemId: model.id!,
                        );
                      });
                    });
                  }
                },
                contextColor.secondaryColor,
                contextColor.territoryColor,
              ),
            ),
          if (model.status == Constant.statusInactive)
            changeItemStatusWidget(
              buttonName: "activate".translate(context),
              status: Constant.statusActive,
            ),
          if (isDeleteBtnVisible()) deleteItemWidget(),
          if (model.status == Constant.statusActive ||
              model.status == Constant.statusApproved)
            Expanded(
              child: _buildButton(
                model.category!.isJobCategory == 1
                    ? "markAsClosed".translate(context)
                    : "soldOut".translate(context),
                    () async {
                  Navigator.pushNamed(
                    context,
                    Routes.soldOutBoughtScreen,
                    arguments: {
                      "itemId": model.id,
                      "price": model.price,
                      "itemName": model.translatedName,
                      "itemImage": model.image,
                      "isJobCategory": model.category!.isJobCategory == 1,
                    },
                  );
                },
                null,
                null,
              ),
            ),
          if (model.status == Constant.statusSoftRejected)
            changeItemStatusWidget(
              buttonName: "resubmit".translate(context),
              status: Constant.statusResubmitted,
            ),
        ],
      );
    } else {
      // Normal user (not owner)
      final isDonation = model.category?.categoryType == 'donation';

      final isSwip = model.category?.categoryType == 'swip';
      // final isClassic = model.category?.categoryType == 'classic' || model.category?.categoryType == null;

      // return Row(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     // Show number button
      //     Expanded(
      //       child: _buildButton(
      //         isDonation ? 'رقم التواصل'.translate(context) : 'عرض الرقم'.translate(context),
      //             () {
      //           if (isDonation) {
      //             _showPhoneNumber();
      //           } else {
      //             _checkPaymentStatus().then((isPaid) {
      //               if (isPaid) {
      //                 _showPhoneNumber();
      //               } else {
      //                 _showPaymentDialog();
      //               }
      //             });
      //           }
      //         },
      //         null,
      //         null,
      //       ),
      //     ),
      //     const SizedBox(width: 10),
      //     // Chat button
      //     Expanded(
      //       child: _buildButton(
      //         'chat'.translate(context),
      //         _openChat,
      //         null,
      //         null,
      //       ),
      //     ),
      //   ],
      // );
      return Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 1. زر التواصل (رقم الهاتف / الإيميل)
          // يظهر فقط في حالة التبرع (مجاني) أو العادي (بعد التحقق من الدفع)
          // ويختفي تماماً في حالة المقايضة حسب طلبك
          if (!isSwip)
            Expanded(
              child: _buildButton(
                isDonation ? "contactNumber".translate(context) : "showNumber".translate(context),
                    () {
                  if (isDonation) {
                    _showPhoneNumber(); // تبرع: اظهر الرقم مباشرة
                  } else {
                    // عادي: تحقق من حالة الدفع أولاً
                    _checkPaymentStatus().then((isPaid) {
                      if (isPaid) {
                        _showPhoneNumber();
                      } else {
                        _showPaymentDialog(); // اطلب الدفع (المبلغ المستخرج من system settings)
                      }
                    });
                  }
                },
                null,
                null,
              ),
            ),

          // 2. زر الدردشة (Chat)
          // يظهر في كل الحالات، ولكن في "العادي" يجب التأكد من الدفع أولاً
          Expanded(
            child: _buildButton(
              "chat".translate(context),
                  () {
                if (isSwip || isDonation) {
                  _openChat(); // مقايضة أو تبرع: افتح الدردشة مباشرة مجاناً
                } else {
                  // عادي: تحقق من الدفع قبل فتح الشات
                  _checkPaymentStatus().then((isPaid) {
                    if (isPaid) {
                      _openChat();
                    } else {
                      _showPaymentDialog();
                    }
                  });
                }
              },
              // نغير لون الزر ليكون مميزاً في حالة المقايضة بما أنه الزر الوحيد
              isSwip ? context.color.territoryColor : null,
              isSwip ? context.color.secondaryColor : null,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildButton(
      String title,
      VoidCallback onPressed,
      Color? buttonColor,
      Color? textColor,
      ) {
    return UiUtils.buildButton(
      context,
      onPressed: onPressed,
      radius: 10,
      height: 46,
      border: buttonColor != null
          ? BorderSide(color: context.color.territoryColor)
          : null,
      buttonColor: buttonColor,
      textColor: textColor,
      buttonTitle: title,
      width: 50,
    );
  }

  // The rest of your existing methods (reportedAdsWidget, relatedAds, etc.) remain unchanged.
  // I'll include them briefly for completeness, but they are not modified.

  Widget reportedAdsWidget() {
    return BlocBuilder<UpdatedReportItemCubit, UpdatedReportItemState>(
      builder: (context, state) {
        bool isItemInCubit = context
            .read<UpdatedReportItemCubit>()
            .containsItem(model.id!);

        if (!isItemInCubit) {
          if (model.isAlreadyReported != null && !model.isAlreadyReported!) {
            return setReportAd();
          } else {
            return const SizedBox();
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget relatedAds() {
    return BlocBuilder<FetchRelatedItemsCubit, FetchRelatedItemsState>(
      builder: (context, state) {
        if (state is FetchRelatedItemsInProgress) {
          return relatedItemShimmer();
        }
        if (state is FetchRelatedItemsFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return NoInternet(
                onRetry: () {
                  context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
                    categoryId: categoryId!,
                    location: location,
                  );
                },
              );
            }
          }
          return const SomethingWentWrong();
        }
        if (state is FetchRelatedItemsSuccess) {
          if (state.itemModel.isEmpty || state.itemModel.length == 1) {
            return const SizedBox.shrink();
          }
          return buildRelatedListWidget(state);
        }
        return const SizedBox.square();
      },
    );
  }

  Widget buildRelatedListWidget(FetchRelatedItemsSuccess state) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "relatedAds".translate(context),
            fontSize: context.font.large,
            fontWeight: FontWeight.w600,
            maxLines: 1,
          ),
          const SizedBox(height: 15),
          GridListAdapter(
            type: ListUiType.List,
            height: MediaQuery.of(context).size.height / 3.2,
            controller: _pageScrollController,
            listAxis: Axis.horizontal,
            listSeparator: (BuildContext p0, int p1) => const SizedBox(width: 14),
            isNotSidePadding: true,
            builder: (context, int index, bool) {
              ItemModel? item = state.itemModel[index];
              if (item.id != model.id) {
                return ItemCard(item: item, width: 162);
              } else {
                return const SizedBox.shrink();
              }
            },
            total: state.itemModel.length,
          ),
        ],
      ),
    );
  }

  Widget relatedItemShimmer() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: 5,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 8),
            child: const CustomShimmer(height: 200, width: 300),
          );
        },
      ),
    );
  }

  Widget createFeaturesAds() {
    if (model.status == Constant.statusActive ||
        model.status == Constant.statusApproved) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => CreateFeaturedAdCubit()),
          BlocProvider(create: (context) => FetchUserPackageLimitCubit()),
        ],
        child: Builder(
          builder: (context) {
            return BlocListener<CreateFeaturedAdCubit, CreateFeaturedAdState>(
              listener: (context, state) {
                if (state is CreateFeaturedAdInSuccess) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.responseMessage.toString(),
                    messageDuration: 3,
                  );
                  Navigator.pop(context, "refresh");
                }
                if (state is CreateFeaturedAdFailure) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.error.toString(),
                    messageDuration: 3,
                  );
                }
              },
              child: BlocListener<FetchUserPackageLimitCubit, FetchUserPackageLimitState>(
                listener: (context, state) async {
                  if (state is FetchUserPackageLimitFailure) {
                    UiUtils.noPackageAvailableDialog(context);
                  }
                  if (state is FetchUserPackageLimitInSuccess) {
                    await UiUtils.showBlurredDialoge(
                      context,
                      dialoge: BlurredDialogBox(
                        title: "createFeaturedAd".translate(context),
                        content: CustomText(
                          "areYouSureToCreateThisItemAsAFeaturedAd".translate(context),
                        ),
                        isAcceptContainerPush: true,
                        onAccept: () => Future.value().then((_) {
                          if (context
                              .read<FetchUserPackageLimitCubit>()
                              .state
                          is FetchUserPackageLimitInProgress) {
                            return;
                          }
                          Future.delayed(Duration.zero, () {
                            context
                                .read<CreateFeaturedAdCubit>()
                                .createFeaturedAds(itemId: model.id!);
                            Navigator.pop(context);
                          });
                        }),
                      ),
                    );
                  }
                },
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 500),
                  crossFadeState: isFeaturedWidget
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: context.color.territoryColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: context.color.textLightColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 12),
                          child: SvgPicture.asset(
                            AppIcons.createAddIcon,
                            height: 74,
                            width: 62,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "${"featureYourAdsAttractMore".translate(context)}\n${"clientsAndSellFaster".translate(context)}",
                                color: context.color.textDefaultColor.withValues(alpha: 0.7),
                                fontSize: context.font.large,
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  context
                                      .read<FetchUserPackageLimitCubit>()
                                      .fetchUserPackageLimit(
                                    packageType: "advertisement",
                                  );
                                },
                                child: Container(
                                  height: 33,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: context.color.territoryColor,
                                  ),
                                  child: CustomText(
                                    "createFeaturedAd".translate(context),
                                    color: context.color.secondaryColor,
                                    fontSize: context.font.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  secondChild: const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget customFields() {
    final List<dynamic> allFields = model.allTranslatedCustomFields ?? [];
    final int currentLanguageId = (HiveUtils.getLanguage()?['id'] ?? 1) as int;

    final Map<int, Map<int, dynamic>> fieldsByIdAndLang = {};
    for (var field in allFields) {
      final int id = field['id'];
      final int langId = field['language_id'] ?? 1;
      fieldsByIdAndLang.putIfAbsent(id, () => {});
      fieldsByIdAndLang[id]![langId] = field;
    }

    final Map<int, dynamic> uniqueFields = {};
    fieldsByIdAndLang.forEach((id, langMap) {
      if (langMap.containsKey(currentLanguageId)) {
        uniqueFields[id] = langMap[currentLanguageId];
      } else {
        uniqueFields[id] = langMap.values.first;
      }
    });

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Wrap(
        runSpacing: 5.0,
        spacing: 5.0,
        children: uniqueFields.values
            .where(
              (field) =>
          field['value'] != null &&
              (field['value'] is List && (field['value'] as List).isNotEmpty),
        )
            .map((field) {
          return DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withValues(alpha: 0.0)),
            ),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .45,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 33,
                    width: 33,
                    alignment: Alignment.center,
                    child: UiUtils.imageType(
                      field['image']!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: field['translated_name'],
                          child: CustomText(
                            field['translated_name'] ?? "",
                            fontSize: context.font.small,
                            color: context.color.textLightColor,
                          ),
                        ),
                        if (field['type'] == 'fileinput')
                          valueContent(field['value'])
                        else
                          valueContent(field['translated_selected_values']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        })
            .toList(),
      ),
    );
  }

  Widget valueContent(List<dynamic>? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    if ((value[0].toString()).startsWith("http") ||
        (value[0].toString()).startsWith("https")) {
      if ((value[0].toString()).toLowerCase().endsWith(".pdf")) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              Routes.pdfViewerScreen,
              arguments: {"url": value[0]},
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: UiUtils.getSvg(
              AppIcons.pdfIcon,
              color: context.color.textColorDark,
              width: 24,
              height: 24,
            ),
          ),
        );
      } else if ((value[0]).toLowerCase().endsWith(".png") ||
          (value[0]).toLowerCase().endsWith(".jpg") ||
          (value[0]).toLowerCase().endsWith(".jpeg") ||
          (value[0]).toLowerCase().endsWith(".svg")) {
        return InkWell(
          onTap: () {
            UiUtils.showFullScreenImage(
              context,
              provider: NetworkImage(value[0]),
            );
          },
          child: Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.color.territoryColor.withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: UiUtils.imageType(
                value[0],
                color: context.color.territoryColor,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * .3,
      child: CustomText(
        value.length == 1 ? value[0].toString() : value.join(','),
        softWrap: true,
        color: context.color.textDefaultColor,
      ),
    );
  }

  Widget deleteItemWidget() {
    return BlocProvider(
      create: (context) => DeleteItemCubit(),
      child: Builder(
        builder: (context) {
          return BlocListener<DeleteItemCubit, DeleteItemState>(
            listener: (context, deleteState) {
              if (deleteState is DeleteItemSuccess) {
                HelperUtils.showSnackBarMessage(
                  context,
                  "deleteItemSuccessMsg".translate(context),
                );
                context.read<FetchMyItemsCubit>().deleteItem(model);
                Navigator.pop(context, "refresh");
              } else if (deleteState is DeleteItemFailure) {
                HelperUtils.showSnackBarMessage(
                  context,
                  deleteState.errorMessage,
                );
              }
            },
            child: Expanded(
              child: _buildButton(
                "lblremove".translate(context),
                    () async {
                  final delete = await UiUtils.showBlurredDialoge(
                    context,
                    dialoge: BlurredDialogBox(
                      title: "deleteBtnLbl".translate(context),
                      content: CustomText(
                        "deleteitemwarning".translate(context),
                      ),
                    ),
                  ) as bool? ??
                      false;
                  if (delete) {
                    context.read<DeleteItemCubit>().deleteItem(id: model.id!);
                  }
                },
                null,
                null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget changeItemStatusWidget({
    required String buttonName,
    required String status,
  }) {
    return BlocListener<ChangeMyItemStatusCubit, ChangeMyItemStatusState>(
      listener: (context, changeState) {
        if (changeState is ChangeMyItemStatusSuccess) {
          HelperUtils.showSnackBarMessage(
            context,
            "adsStatusUpdatedSuccessfully".translate(context),
          );
          Navigator.pop(context, "refresh");
        } else if (changeState is ChangeMyItemStatusFailure) {
          HelperUtils.showSnackBarMessage(context, changeState.errorMessage);
        }
      },
      child: Expanded(
        child: _buildButton(
          buttonName,
              () {
            Future.delayed(Duration.zero, () {
              context.read<ChangeMyItemStatusCubit>().changeMyItemStatus(
                id: model.id!,
                status: status,
              );
            });
          },
          null,
          null,
        ),
      ),
    );
  }

  bool isEditBtnVisible() {
    List statuslist = [
      Constant.statusReview,
      Constant.statusResubmitted,
      Constant.statusActive,
      Constant.statusApproved,
      Constant.statusSoftRejected,
    ];
    return statuslist.contains(model.status);
  }

  bool isDeleteBtnVisible() {
    List statuslist = [
      Constant.statusReview,
      Constant.statusResubmitted,
      Constant.statusSoldOut,
      Constant.statusInactive,
      Constant.statusExpired,
      Constant.statusPermanentRejected,
    ];
    return statuslist.contains(model.status);
  }

  void safetyTipsBottomSheet() {
    List<SafetyTipsModel>? tipsList = context
        .read<FetchSafetyTipsListCubit>()
        .getList();
    if (tipsList == null || tipsList.isEmpty) {
      makeOfferBottomSheet(model);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: context.color.textColorDark.withValues(alpha: 0.1),
                    ),
                    height: 6,
                    width: 60,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: UiUtils.getSvg(AppIcons.safetyTipsIcon),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 5),
                child: CustomText(
                  'safetyTips'.translate(context),
                  fontWeight: FontWeight.w600,
                  fontSize: context.font.larger,
                  textAlign: TextAlign.center,
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: tipsList.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return checkmarkPoint(
                    context,
                    tipsList[index].translatedName!,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildButton(
                  "continueToOffer".translate(context),
                      () {
                    Navigator.pop(context);
                    makeOfferBottomSheet(model);
                  },
                  context.color.territoryColor,
                  context.color.secondaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiUtils.getSvg(AppIcons.active_mark),
          const SizedBox(width: 12),
          Expanded(
            child: CustomText(
              text.firstUpperCase(),
              textAlign: TextAlign.start,
              color: context.color.textDefaultColor,
              fontSize: context.font.large,
            ),
          ),
        ],
      ),
    );
  }

  // ImageViewer and related methods
  Widget setImageViewer() {
    return Container(
      height: 300,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: pageController,
              itemBuilder: (context, index) {
                if (index == images.length - 1 &&
                    model.videoLink != null &&
                    model.videoLink!.isNotEmpty) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return VideoViewScreen(
                                  videoUrl: model.videoLink ?? "",
                                  flickManager: flickManager,
                                );
                              },
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: UiUtils.getImage(
                            youtubeVideoThumbnail,
                            fit: BoxFit.cover,
                            height: 300,
                            width: double.maxFinite,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return VideoViewScreen(
                                    videoUrl: model.videoLink ?? "",
                                    flickManager: flickManager,
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x7F060606),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.darken,
                    child: InkWell(
                      onTap: () {
                        UiUtils.imageGallaryView(
                          context,
                          images: images,
                          initalIndex: index,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: UiUtils.getImage(
                          images[index]!,
                          fit: BoxFit.cover,
                          height: 300,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images
                      .asMap()
                      .keys
                      .map((index) => buildDot(index))
                      .toList(),
                ),
              ),
            ),
            if (model.isFeature != null && model.isFeature!)
              setTopRowItem(
                alignment: AlignmentDirectional.topStart,
                marginVal: 15,
                cornerRadius: 5,
                backgroundColor: context.color.territoryColor,
                childWidget: CustomText(
                  "featured".translate(context),
                  fontSize: context.font.small,
                  color: context.color.backgroundColor,
                ),
              ),
            favouriteButton(),
          ],
        ),
      ),
    );
  }

  Widget favouriteButton() {
    if (!isAddedByMe) {
      return BlocBuilder<FavoriteCubit, FavoriteState>(
        bloc: context.read<FavoriteCubit>(),
        builder: (context, favState) {
          bool isLike = context.select(
                (FavoriteCubit cubit) => cubit.isItemFavorite(model.id!),
          );

          return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
            bloc: context.read<UpdateFavoriteCubit>(),
            listener: (context, state) {
              if (state is UpdateFavoriteSuccess) {
                if (state.wasProcess) {
                  context.read<FavoriteCubit>().addFavoriteitem(state.item);
                } else {
                  context.read<FavoriteCubit>().removeFavoriteItem(state.item);
                }
              }
            },
            builder: (context, state) {
              return setTopRowItem(
                alignment: AlignmentDirectional.topEnd,
                marginVal: 10,
                backgroundColor: context.color.backgroundColor,
                cornerRadius: 30,
                childWidget: InkWell(
                  onTap: () {
                    UiUtils.checkUser(
                      onNotGuest: () {
                        context.read<UpdateFavoriteCubit>().setFavoriteItem(
                          item: model,
                          type: isLike ? 0 : 1,
                        );
                      },
                      context: context,
                    );
                  },
                  child: state is UpdateFavoriteInProgress
                      ? UiUtils.progress(height: 22, width: 22)
                      : UiUtils.getSvg(
                    isLike ? AppIcons.like_fill : AppIcons.like,
                    color: context.color.territoryColor,
                    width: 22,
                    height: 22,
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setTopRowItem({
    required AlignmentDirectional alignment,
    required double marginVal,
    required double cornerRadius,
    required Color backgroundColor,
    required Widget childWidget,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.all(marginVal),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          color: backgroundColor,
        ),
        child: childWidget,
      ),
    );
  }

  Widget buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.0),
      width: currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: currentPage == index ? Colors.white : Colors.grey,
      ),
    );
  }

  Widget setLikesAndViewsCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  width: 1,
                  color: context.color.textDefaultColor.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiUtils.getSvg(
                    AppIcons.eye,
                    color: context.color.textDefaultColor,
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    model.views != null ? model.views!.toString() : "0",
                    color: context.color.textDefaultColor.withValues(alpha: 0.8),
                    fontSize: context.font.large,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  width: 1,
                  color: context.color.textDefaultColor.withValues(alpha: 0.1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiUtils.getSvg(
                    AppIcons.like,
                    color: context.color.textDefaultColor,
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    model.totalLikes == null ? "0" : model.totalLikes.toString(),
                    color: context.color.textDefaultColor.withValues(alpha: 0.8),
                    fontSize: context.font.large,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget setRejectedReason() {
    if (model.status == Constant.statusPermanentRejected ||
        (model.status == Constant.statusSoftRejected &&
            (model.translatedRejectedReason != null &&
                model.translatedRejectedReason!.isNotEmpty))) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.color.textDefaultColor.withValues(alpha: 0.1),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 15),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.report,
              size: 20,
              color: Colors.red,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: CustomText(
                '${"rejection_reason".translate(context)}: ${model.translatedRejectedReason ?? 'N/A'}',
                color: context.color.textDefaultColor,
                fontSize: context.font.large,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget adminEditedReason() {
    String message = model.translatedAdminEditReason!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deactivateButtonColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: deactivateButtonColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiUtils.getSvg(
            AppIcons.adminEditIcon,
            height: 40,
            width: 40,
            color: deactivateButtonColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "adEditedBy".translate(context),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                      TextSpan(
                        text: "\t${"admin".translate(context)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final span = TextSpan(
                      text: message,
                      style: TextStyle(color: context.color.textDefaultColor),
                    );
                    final tp = TextPainter(
                      text: span,
                      maxLines: 2,
                      textDirection: TextDirection.ltr,
                    );
                    tp.layout(maxWidth: (constraints.maxWidth - 65));
                    final isOverflowing = tp.didExceedMaxLines;

                    String displayText = message;
                    if (!isAdminEditedReasonExpanded && isOverflowing) {
                      int endIndex = tp
                          .getPositionForOffset(Offset(tp.width, tp.height))
                          .offset;
                      displayText = message.substring(0, endIndex).trim();
                    }

                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: isAdminEditedReasonExpanded || !isOverflowing
                                ? message
                                : displayText + "...",
                            style: TextStyle(
                              color: context.color.textDefaultColor,
                            ),
                          ),
                          if (isOverflowing)
                            TextSpan(
                              text: isAdminEditedReasonExpanded
                                  ? "\t${"readLessLbl".translate(context)}"
                                  : "\t${"readMoreLbl".translate(context)}",
                              style: const TextStyle(
                                color: deactivateButtonColor,
                                fontWeight: FontWeight.w600,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    isAdminEditedReasonExpanded =
                                    !isAdminEditedReasonExpanded;
                                  });
                                },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget setPriceAndStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _buildTypeIndicator(context),
          ),
        ),
        if (model.status != null && isAddedByMe)
          Container(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _getStatusColor(model.status),
            ),
            child: CustomText(
              _getStatusCustomText(model.status)!,
              fontSize: context.font.normal,
              color: _getStatusTextColor(model.status),
            ),
          ),
      ],
    );
  }

  String? _getStatusCustomText(String? status) {
    switch (status) {
      case Constant.statusReview:
        return "underReview".translate(context);
      case Constant.statusActive:
        return "active".translate(context);
      case Constant.statusApproved:
        return "approved".translate(context);
      case Constant.statusInactive:
        return "deactivate".translate(context);
      case Constant.statusSoldOut:
        return model.category!.isJobCategory == 1
            ? "jobClosed".translate(context)
            : "soldOut".translate(context);
      case Constant.statusPermanentRejected:
        return "permanentRejected".translate(context);
      case Constant.statusSoftRejected:
        return "softRejected".translate(context);
      case Constant.statusExpired:
        return "expired".translate(context);
      case Constant.statusResubmitted:
        return "resubmitted".translate(context);
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case Constant.statusReview:
      case Constant.statusResubmitted:
        return pendingButtonColor.withValues(alpha: 0.1);
      case Constant.statusActive:
      case Constant.statusApproved:
        return activateButtonColor.withValues(alpha: 0.1);
      case Constant.statusInactive:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusSoldOut:
        return soldOutButtonColor.withValues(alpha: 0.1);
      case Constant.statusPermanentRejected:
      case Constant.statusSoftRejected:
        return deactivateButtonColor.withValues(alpha: 0.1);
      case Constant.statusExpired:
        return deactivateButtonColor.withValues(alpha: 0.1);
      default:
        return context.color.territoryColor.withValues(alpha: 0.1);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case Constant.statusReview:
      case Constant.statusResubmitted:
        return pendingButtonColor;
      case Constant.statusActive:
      case Constant.statusApproved:
        return activateButtonColor;
      case Constant.statusInactive:
        return deactivateButtonColor;
      case Constant.statusSoldOut:
        return soldOutButtonColor;
      case Constant.statusPermanentRejected:
      case Constant.statusSoftRejected:
        return deactivateButtonColor;
      case Constant.statusExpired:
        return deactivateButtonColor;
      default:
        return context.color.territoryColor;
    }
  }

  Widget setAddress() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppIcons.location,
            colorFilter: ColorFilter.mode(
              context.color.territoryColor,
              BlendMode.srcIn,
            ),
          ),
          Expanded(
            child: CustomText(
              UiUtils.formatDisplayAddress(model.translatedAddress ?? ''),
              color: context.color.textDefaultColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget setDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          "aboutThisItemLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: CustomText(
            model.translatedDescription!,
            color: context.color.textDefaultColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  void _navigateToGoogleMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        barrierDismissible: true,
        builder: (context) {
          return GoogleMapScreen(controller: _locationController!);
        },
      ),
    );
  }

  Widget setLocation() {
    if (_locationController == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "locationLbl".translate(context),
          fontWeight: FontWeight.bold,
          fontSize: context.font.large,
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.28,
            child: kReleaseMode && Constant.showGoogleMap
                ? Stack(
              children: [
                LocationMapWidget(
                  controller: _locationController!,
                  showMyLocationButton: false,
                  showMarker: false,
                  interactive: false,
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _navigateToGoogleMapScreen(context);
                    },
                  ),
                ),
              ],
            )
                : Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/map.png', fit: BoxFit.cover),
                ),
                Center(
                  child: MaterialButton(
                    onPressed: () {
                      _navigateToGoogleMapScreen(context);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    color: context.color.territoryColor,
                    elevation: 0,
                    child: CustomText(
                      'viewMap'.translate(context),
                      color: context.color.buttonColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget setReportAd() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      crossFadeState: isShowReportAds
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.color.textDefaultColor.withValues(alpha: 0.1),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.report,
                  size: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: CustomText(
                    "didYouFindAnyProblemWithThisItem".translate(context),
                    maxLines: 2,
                    fontSize: context.font.large,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            BlocListener<ItemReportCubit, ItemReportState>(
              listener: (context, state) {
                if (state is ItemReportFailure) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.error.toString(),
                  );
                }
                if (state is ItemReportInSuccess) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.responseMessage.toString(),
                  );
                  context.read<UpdatedReportItemCubit>().addItem(model);
                }
                if (!Constant.isDemoModeOn) {
                  setState(() {
                    isShowReportAds = false;
                  });
                }
              },
              child: GestureDetector(
                onTap: () {
                  UiUtils.checkUser(
                    onNotGuest: () {
                      _bottomSheet(model.id!);
                    },
                    context: context,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: context.color.territoryColor.withValues(alpha: 0.1),
                  ),
                  child: CustomText(
                    "reportThisAd".translate(context),
                    color: context.color.territoryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }

  void makeOfferBottomSheet(ItemModel model) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: makeAnOffer(),
        onCancel: () {
          _makeAnOfferMessageController.clear();
        },
        acceptButtonName: "send".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_offerFormKey.currentState!.validate()) {
            context.read<MakeAnOfferItemCubit>().makeAnOfferItem(
              id: model.id!,
              from: "offer",
              amount: double.parse(_makeAnOfferMessageController.text.trim()),
            );
            Navigator.pop(context);
          }
        }),
      ),
    );
  }

  Widget makeAnOffer() {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _offerFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "makeAnOffer".translate(context),
                fontSize: context.font.larger,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              Divider(
                thickness: 1,
                color: context.color.textLightColor.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 15),
              RichText(
                text: TextSpan(
                  text: '${"sellerPrice".translate(context)} ',
                  style: TextStyle(
                    color: context.color.textDefaultColor.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: model.price!.currencyFormat,
                      style: TextStyle(
                        color: context.color.textDefaultColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                  start: 20,
                  end: 20,
                  top: 18,
                ),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: context.color.textDefaultColor,
                  ),
                  controller: _makeAnOfferMessageController,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val, context: context);
                    } else {
                      double parsedVal = double.parse(val);
                      if (parsedVal <= 0.0) {
                        return "valueMustBeGreaterThanZeroLbl".translate(context);
                      } else if (parsedVal > model.price!) {
                        return "offerPriceWarning".translate(context);
                      }
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                    fillColor: context.color.textLightColor.withValues(alpha: 0.15),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                    hintText: "yourOffer".translate(context),
                    hintStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: context.color.textDefaultColor.withValues(alpha: 0.3),
                    ),
                    focusColor: context.color.territoryColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.color.textLightColor.withValues(alpha: 0.35),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: context.color.textLightColor.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: context.color.territoryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bottomSheet(int itemId) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: "reportItem".translate(context),
        content: reportReason(),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (selectedId.isNegative) {
            if (_formKey.currentState!.validate()) {
              context.read<ItemReportCubit>().report(
                item_id: model.id!,
                reason_id: selectedId,
                message: _reportMessageController.text,
              );
              Navigator.pop(context);
            }
          } else {
            context.read<ItemReportCubit>().report(
              item_id: model.id!,
              reason_id: selectedId,
            );
            Navigator.pop(context);
          }
        }),
      ),
    );
  }

  String formatPhoneNumber(String fullNumber, String countryCode) {
    countryCode = countryCode.replaceAll('+', '');
    fullNumber = fullNumber.replaceAll('+', '');
    if (!fullNumber.startsWith(countryCode)) {
      fullNumber = countryCode + fullNumber;
    }
    fullNumber = '+' + fullNumber;
    return fullNumber;
  }

  void navigateToSellerProfile() {
    Navigator.pushNamed(
      context,
      Routes.sellerProfileScreen,
      arguments: {"sellerId": model.user!.id},
    );
  }

  Widget setSellerDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          InkWell(
            onTap: navigateToSellerProfile,
            child: SizedBox(
              height: 60,
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: model.user!.profile != null && model.user!.profile!.isNotEmpty
                    ? UiUtils.getImage(model.user!.profile!, fit: BoxFit.fill)
                    : UiUtils.getSvg(
                  AppIcons.defaultPersonLogo,
                  color: context.color.territoryColor,
                  fit: BoxFit.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.user!.isVerified == 1)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: context.color.forthColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          UiUtils.getSvg(
                            AppIcons.verifiedIcon,
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          CustomText(
                            "verifiedLbl".translate(context),
                            color: context.color.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  InkWell(
                    onTap: navigateToSellerProfile,
                    child: CustomText(
                      model.user!.name!,
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.large,
                    ),
                  ),
                  if (context.watch<FetchSellerRatingsCubit>().sellerData() != null &&
                      context
                          .watch<FetchSellerRatingsCubit>()
                          .sellerData()!
                          .averageRating !=
                          null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            TextSpan(
                              text:
                              '\t${context.watch<FetchSellerRatingsCubit>().sellerData()!.averageRating!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            TextSpan(
                              text: '  |  ',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.color.textDefaultColor.withValues(alpha: 0.5),
                              ),
                            ),
                            TextSpan(
                              text:
                              '${context.watch<FetchSellerRatingsCubit>().totalSellerRatings()}\t${"ratings".translate(context)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.color.textDefaultColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (model.user!.showPersonalDetails == 1 &&
                      model.user!.email != null &&
                      model.user!.email!.isNotEmpty)
                    InkWell(
                      onTap: navigateToSellerProfile,
                      child: CustomText(
                        model.user!.email!,
                        color: context.color.textLightColor,
                        fontSize: context.font.small,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (model.user!.showPersonalDetails == 1 &&
              model.user!.mobile != null &&
              model.user!.mobile!.isNotEmpty)
            setIconButtons(
              assetName: AppIcons.message,
              onTap: () {
                HelperUtils.launchPathURL(
                  isTelephone: false,
                  isSMS: true,
                  isMail: false,
                  value: formatPhoneNumber(
                    model.contact ?? model.user!.mobile!,
                    Constant.defaultCountryCode,
                  ),
                  context: context,
                );
              },
            ),
          const SizedBox(width: 10),
          if (model.user!.showPersonalDetails == 1 &&
              model.user!.mobile != null &&
              model.user!.mobile!.isNotEmpty)
            setIconButtons(
              assetName: AppIcons.call,
              onTap: () {
                HelperUtils.launchPathURL(
                  isTelephone: true,
                  isSMS: false,
                  isMail: false,
                  value: formatPhoneNumber(
                    model.user!.mobile!,
                    Constant.defaultCountryCode,
                  ),
                  context: context,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget setIconButtons({
    required String assetName,
    required VoidCallback onTap,
    Color? color,
    double? height,
    double? width,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.color.textLightColor.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: InkWell(
          onTap: onTap,
          child: SvgPicture.asset(
            assetName,
            colorFilter: color == null
                ? ColorFilter.mode(
              context.color.territoryColor,
              BlendMode.srcIn,
            )
                : ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Widget reportReason() {
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom - 50;
    bool isBottomPaddingNegative = bottomPadding.isNegative;
    reasons = context.read<FetchItemReportReasonsListCubit>().getList() ?? [];

    if (reasons?.isEmpty ?? true) {
      selectedId = -10;
    } else {
      selectedId = reasons!.first.id;
    }
    return StatefulBuilder(
      builder: (context, setState) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: reasons?.length ?? 0,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            selectedId = reasons![index].id;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.color.primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedId == reasons![index].id
                                  ? context.color.territoryColor
                                  : context.color.borderColor,
                              width: 1.8,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: CustomText(
                              reasons![index].reason,
                              color: selectedId == reasons![index].id
                                  ? context.color.territoryColor
                                  : context.color.textColorDark,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (selectedId.isNegative)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: isBottomPaddingNegative ? 0 : bottomPadding,
                        start: 0,
                        end: 0,
                      ),
                      child: TextFormField(
                        maxLines: null,
                        controller: _reportMessageController,
                        cursorColor: context.color.territoryColor,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "addReportReason".translate(context);
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "writeReasonHere".translate(context),
                          focusColor: context.color.territoryColor,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: context.color.territoryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}