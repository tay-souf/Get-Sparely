import 'dart:math';

import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/category/fetch_category_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/model/item/item_filter.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/ui/screens/home/widgets/category_home_card.dart';
import 'package:eClassify/ui/screens/main_activity.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryWidgetHome extends StatelessWidget {
  const CategoryWidgetHome({super.key});

  final int maxLimit = 10;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
        builder: (context, state) {
          if (state is FetchCategoryFailure) {
            return const SizedBox.shrink();
          }
          if (state is FetchCategorySuccess) {
            if (state.categories.isNotEmpty) {
              final length = min(state.categories.length, maxLimit);
              final showMoreCategory = length >= maxLimit;


              if (length == 3 && !showMoreCategory) {
                return SizedBox(
                  height: 135,
                  child: Row(
                    children: List.generate(length, (index) {
                      final category = state.categories[index];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 6.0,
                            right: index == length - 1 ? 0 : 6.0,
                          ),
                          child: CategoryHomeCard(
                            title: category.name!,
                            url: category.url!,
                            onTap: () {
                              if (category.children!.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  Routes.subCategoryScreen,
                                  arguments: {
                                    "categoryList": category.children,
                                    "catName": category.name,
                                    "catId": category.id,
                                    "categoryIds": [category.id.toString()],
                                  },
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  Routes.itemsList,
                                  arguments: CategoryMetaData(
                                    categoryId: category.id.toString(),
                                    categoryIds: [category.id.toString()],
                                    title: category.name!,
                                    filter: ItemFilter(category: category),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }

              // الوضع العادي مع ListView أفقي
              return SizedBox(
                height: 105,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: showMoreCategory ? length + 1 : length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    if (index == length && showMoreCategory) {
                      return moreCategory(context);
                    } else {
                      return CategoryHomeCard(
                        title: category.name!,
                        url: category.url!,
                        onTap: () {
                          if (category.children!.isNotEmpty) {
                            Navigator.pushNamed(
                              context,
                              Routes.subCategoryScreen,
                              arguments: {
                                "categoryList": category.children,
                                "catName": category.name,
                                "catId": category.id,
                                "categoryIds": [category.id.toString()],
                              },
                            );
                          } else {
                            Navigator.pushNamed(
                              context,
                              Routes.itemsList,
                              arguments: CategoryMetaData(
                                categoryId: category.id.toString(),
                                categoryIds: [category.id.toString()],
                                title: category.name!,
                                filter: ItemFilter(category: category),
                              ),
                            );
                          }
                        },
                      );
                    }
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 12);
                  },
                ),
              );
            }
          }
          // حالة التحميل (shimmer)
          return SizedBox(
            height: 100,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: index == 0 ? 0 : 8.0,
                  ),
                  child: const Column(
                    children: [
                      CustomShimmer(height: 70, width: 66, borderRadius: 10),
                      CustomShimmer(
                        height: 10,
                        width: 48,
                        margin: EdgeInsetsDirectional.only(top: 5),
                      ),
                      CustomShimmer(
                        height: 10,
                        width: 60,
                        margin: EdgeInsetsDirectional.only(top: 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget moreCategory(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppTheme>(
      builder: (context, state) {
        return SizedBox(
          width: 70,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.categories,
                arguments: {"from": Routes.home},
              ).then((dynamic value) {
                if (value != null) {
                  selectedCategory = value;
                }
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                spacing: 4,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: context.color.textLightColor.withValues(
                          alpha: 0.33,
                        ),
                        width: 1,
                      ),
                      color: context.color.secondaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: UiUtils.getSvg(
                              AppIcons.more,
                              color: context.color.territoryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomText(
                      "more".translate(context),
                      textAlign: TextAlign.center,
                      fontSize: context.font.smaller,
                      color: context.color.textDefaultColor.withValues(
                        alpha: .7,
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
