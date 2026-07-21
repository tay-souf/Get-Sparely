// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/auth/user_profile_cubit.dart';
import 'package:eClassify/data/cubits/category/fetch_category_cubit.dart';
import 'package:eClassify/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:eClassify/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:eClassify/data/cubits/item/job_application/fetch_job_application_cubit.dart';
import 'package:eClassify/data/cubits/location/leaf_location_cubit.dart';
import 'package:eClassify/data/cubits/slider_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/screens/ad_banner_screen.dart';
import 'package:eClassify/ui/screens/home/mixins/root_location_resolver_mixin.dart';
import 'package:eClassify/ui/screens/home/slider_widget.dart';
import 'package:eClassify/ui/screens/home/widgets/category_widget_home.dart';
import 'package:eClassify/ui/screens/home/widgets/featured_section_widget.dart';
import 'package:eClassify/ui/screens/home/widgets/home_search.dart';
import 'package:eClassify/ui/screens/home/widgets/item_card_widget.dart';
import 'package:eClassify/ui/screens/home/widgets/location_widget.dart';
import 'package:eClassify/ui/screens/native_ads_screen.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';

const double sidePadding = 10;

class HomeScreen extends StatefulWidget {
  final String? from;

  const HomeScreen({super.key, this.from});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with
        AutomaticKeepAliveClientMixin<HomeScreen>,
        WidgetsBindingObserver,
        RootLocationResolverMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _initialConfiguration();

    if (HiveUtils.isUserAuthenticated()) {
      _initialApiCalls();
    }

    _scrollController.addListener(() {
      if (_scrollController.isEndReached()) {
        if (context.read<FetchHomeAllItemsCubit>().hasMoreData()) {
          context.read<FetchHomeAllItemsCubit>().fetchMore(
            location: HiveUtils.getLocation(),
          );
        }
      }
    });
  }

  void _initialConfiguration() async {
    initializeSettings();
    await notificationPermissionChecker();
    loadInitialInfo();
  }

  void _initialApiCalls() {
    context.read<FavoriteCubit>().getFavorite();
    context.read<GetBuyerChatListCubit>().fetch();
    context.read<FetchJobApplicationCubit>().fetchApplications(
      itemId: 0,
      isMyJobApplications: true,
    );
    context.read<BlockedUsersListCubit>().blockedUsersList();
    if (widget.from != 'profile_screen') {
      context.read<UserProfileCubit>().getUserProfile();
    }
    HelperUtils.maybeSubscribeToTopics();
  }

  void loadInitialInfo() async {
    var location = context.read<LeafLocationCubit>().state;
    if (location != null) {
      context.read<FetchHomeScreenCubit>().fetch(location: location);
      context.read<FetchHomeAllItemsCubit>().fetch(location: location);
    }
    context.read<SliderCubit>().fetchSlider(context);
    context.read<FetchCategoryCubit>().fetchCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void initializeSettings() {
    final settingsCubit = context.read<FetchSystemSettingsCubit>();
    if (!bool.fromEnvironment(
      Constant.forceDisableDemoMode,
      defaultValue: false,
    )) {
      Constant.isDemoModeOn =
          settingsCubit.getSetting(SystemSetting.demoMode) ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<LeafLocationCubit, LeafLocation?>(
      listener: (context, state) {
        context.read<FetchHomeScreenCubit>().fetch(location: state);
        context.read<FetchHomeAllItemsCubit>().fetch(location: state);
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            leadingWidth: double.maxFinite,
            leading: Padding(
              padding: EdgeInsetsDirectional.only(
                start: sidePadding,
                end: sidePadding,
              ),
              child: LocationWidget(),
            ),
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          ),
          backgroundColor: context.color.primaryColor,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: sidePadding),
            child: RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              color: context.color.territoryColor,
              onRefresh: () async => loadInitialInfo(),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: HomeSearchField()),
                  SliverToBoxAdapter(child: SliderWidget()),
                  SliverToBoxAdapter(child: CategoryWidgetHome()),
                  BlocBuilder<FetchHomeScreenCubit, FetchHomeScreenState>(
                    builder: (context, state) {
                      if (state is FetchHomeScreenSuccess) {
                        if (state.sections.isNotEmpty)
                          return SliverList.builder(
                            itemCount: state.sections.length,
                            itemBuilder: (context, index) {
                              return FeaturedSectionWidget(
                                section: state.sections[index],
                              );
                            },
                          );
                        else
                          return SliverToBoxAdapter(child: const SizedBox());
                      }
                      if (state is FetchHomeScreenFail) {
                        return SliverToBoxAdapter(child: SomethingWentWrong());
                      }
                      return SliverToBoxAdapter(child: shimmerEffect());
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Constant.isGoogleBannerAdsEnabled == "1"
                        ? AdBannerWidget(
                            key: ValueKey('home_banner'),
                            margin: EdgeInsets.symmetric(vertical: 10),
                          )
                        : 10.vGap,
                  ),
                  SliverToBoxAdapter(
                    child:
                        BlocBuilder<
                          FetchHomeAllItemsCubit,
                          FetchHomeAllItemsState
                        >(
                          builder: (context, state) {
                            if (state is FetchHomeAllItemsSuccess) {
                              final isGlobalList =
                                  state.message?.contains('No Ads found') ??
                                  false;
                              if (isGlobalList) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: CustomText(
                                    state.message!,
                                    fontSize: context.font.large,
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                  ),
                  AllItemsWidget(onTapRetry: loadInitialInfo),
                  SliverToBoxAdapter(
                    child: const SizedBox(height: kToolbarHeight / 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget shimmerEffect() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CustomShimmer(height: 20, width: 150),
          ),
          10.vGap,
          Container(
            height: 214,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: 5,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(height: 147, width: 250, borderRadius: 10),
                    CustomShimmer(
                      height: 15,
                      width: 90,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                    const CustomShimmer(
                      height: 14,
                      width: 230,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                    const CustomShimmer(
                      height: 14,
                      width: 200,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) => 10.hGap,
            ),
          ),
        ],
      ),
    );
  }
}

class AllItemsWidget extends StatelessWidget {
  const AllItemsWidget({required this.onTapRetry, super.key});

  final VoidCallback onTapRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeAllItemsCubit, FetchHomeAllItemsState>(
      builder: (context, state) {
        if (state is FetchHomeAllItemsSuccess) {
          final items = state.items;
          final intervalItems = Constant.nativeAdsAfterItemNumber;

          if (items.isNotEmpty) {
            return SliverStaggeredGrid.countBuilder(
              crossAxisCount: 2,
              itemCount: items.length,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (context, index) {
                if (index != 0 && (index + 1) % (intervalItems + 1) == 0) {
                  return const NativeAdWidget(type: TemplateType.medium);
                } else {
                  final item = items[index];
                  return ItemCard(
                    key: ValueKey(items[index].id ?? index),
                    item: item,
                    aspectRatio: .7,
                  );
                }
              },
              staggeredTileBuilder: (index) {
                if (index != 0 && (index + 1) % (intervalItems + 1) == 0) {
                  return const StaggeredTile.fit(2);
                } else {
                  return const StaggeredTile.count(1, 1.5);
                }
              },
            );
          } else {
            return SliverToBoxAdapter(
              child: NoDataFound(
                onTap: () async {
                  final location =
                      await Navigator.pushNamed(context, Routes.locationScreen)
                          as LeafLocation?;
                  if (location == null) return;

                  context.read<LeafLocationCubit>().setLocation(location);
                },
                mainMsgStyle: context.font.larger,
                subMsgStyle: context.font.large,
                mainMessage: "noAdsFound".translate(context),
                subMessage: "noAdsAvailableInThisLocation".translate(context),
                showBtn: false,
                btnName: "changeLocation".translate(context),
              ),
            );
          }
        }
        if (state is FetchHomeAllItemsFail) {
          if (state.error == "no-internet") {
            return SliverToBoxAdapter(child: NoInternet(onRetry: onTapRetry));
          }
          return SliverToBoxAdapter(child: const SomethingWentWrong());
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 214,
            child: GridView.builder(
              itemCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .7,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (_, _) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(height: 147, width: 250, borderRadius: 10),
                    CustomShimmer(
                      height: 15,
                      width: 90,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                    const CustomShimmer(
                      height: 14,
                      width: 230,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                    const CustomShimmer(
                      height: 14,
                      width: 200,
                      margin: EdgeInsetsDirectional.only(top: 8),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

Future<void> notificationPermissionChecker() async {
  if (!(await Permission.notification.isGranted)) {
    await Permission.notification.request();
  }
}
