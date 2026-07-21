import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/widgets/promoted_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

class ItemHorizontalCard extends StatelessWidget {
  final ItemModel item;
  final List<Widget>? addBottom;
  final double? additionalHeight;
  final StatusButton? statusButton;
  final bool? useRow;
  final VoidCallback? onDeleteTap;
  final double? additionalImageWidth;
  final bool? showLikeButton;
  final VoidCallback? onTap;

  const ItemHorizontalCard({
    super.key,
    required this.item,
    this.useRow,
    this.addBottom,
    this.additionalHeight,
    this.statusButton,
    this.onDeleteTap,
    this.showLikeButton,
    this.additionalImageWidth,
    this.onTap,
  });

  Widget favButton(BuildContext context) {
    bool isLike = context.read<FavoriteCubit>().isItemFavorite(item.id!);
    return BlocConsumer<FavoriteCubit, FavoriteState>(
      bloc: context.read<FavoriteCubit>(),
      listener: (context, state) {
        if (state is FavoriteFetchSuccess) {
          // تحديث الواجهة إذا لزم الأمر
        }
      },
      builder: (context, likeAndDislikeState) {
        return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
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
            return InkWell(
              onTap: () {
                UiUtils.checkUser(
                  onNotGuest: () {
                    context.read<UpdateFavoriteCubit>().setFavoriteItem(
                      item: item,
                      type: isLike ? 0 : 1,
                    );
                  },
                  context: context,
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: context.read<AppThemeCubit>().state == AppTheme.dark
                      ? null
                      : [
                    BoxShadow(
                      color: const Color.fromARGB(12, 0, 0, 0),
                      offset: const Offset(0, 2),
                      blurRadius: 10,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.none,
                  child: state is UpdateFavoriteInProgress
                      ? Center(child: UiUtils.progress())
                      : UiUtils.getSvg(
                    isLike ? AppIcons.like_fill : AppIcons.like,
                    width: 22,
                    height: 22,
                    color: context.color.territoryColor,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeIndicator(BuildContext context) {
    String? type = item.category?.categoryType;

    if (type == 'donation') {
      return Row(
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 16),
          const SizedBox(width: 4),
          CustomText(
            'free'.translate(context),
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ],
      );
    } else if (type == 'swip') {
      return Row(
        children: [
          Icon(Icons.swap_horiz, color: Colors.blue, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: CustomText(
              'Wants to swap for : ${item.swipTitle ?? ''}',
              fontSize: context.font.small,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return UiUtils.getPriceWidget(item, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? type = item.category?.categoryType;
    bool isSwip = type == 'swip';
    bool isDonation = type == 'donation';

    return GestureDetector(
      onTap: () {
        onTap?.call();
        Navigator.pushNamed(
          context,
          Routes.adDetailsScreen,
          arguments: {"model": item},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Container(
          height: addBottom == null ? 124 : (124 + (additionalHeight ?? 0)),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.28),
            ),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // صورة الإعلان الرئيسية
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: UiUtils.getImage(
                                item.image ?? "",
                                height: addBottom == null
                                    ? 122
                                    : (122 + (additionalHeight ?? 0)),
                                width: 100 + (additionalImageWidth ?? 0),
                                fit: BoxFit.cover,
                              ),
                            ),
                            // صورة المقايضة
                            if (isSwip && item.swipImage != null)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: UiUtils.getImage(
                                      item.swipImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            if (item.isFeature ?? false)
                              const PositionedDirectional(
                                start: 5,
                                top: 5,
                                child: PromotedCard(type: PromoteCardType.icon),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              top: 0,
                              start: 12,
                              bottom: 5,
                              end: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTypeIndicator(context),
                                    ),
                                    if (showLikeButton ?? true) favButton(context),
                                  ],
                                ),
                                CustomText(
                                  item.translatedName ?? "",
                                  fontSize: context.font.normal,
                                  color: context.color.textDefaultColor,
                                  maxLines: 2,
                                  firstUpperCaseWidget: true,
                                ),
                                if (item.translatedAddress != "")
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: context.color.textDefaultColor
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          UiUtils.formatDisplayAddress(
                                            item.translatedAddress ?? '',
                                          ),
                                          fontSize: context.font.smaller,
                                          color: context.color.textDefaultColor
                                              .withValues(alpha: 0.5),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (item.created != null && item.created != '')
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: context.color.textDefaultColor
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                            start: 2.0,
                                          ),
                                          child: CustomText(
                                            timeago.format(
                                              DateTime.parse(item.created!),
                                              locale: Constant.currentLocale,
                                            ),
                                            fontSize: context.font.smaller,
                                            color: context.color.textDefaultColor
                                                .withValues(alpha: 0.5),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (useRow == false || useRow == null) ...addBottom ?? [],
                  if (useRow == true) ...{Row(children: addBottom ?? [])},
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class StatusButton {
  final String lable;
  final Color color;
  final Color? textColor;

  StatusButton({required this.lable, required this.color, this.textColor});
}
