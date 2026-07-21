import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/favorite/favorite_cubit.dart';
import 'package:eClassify/data/cubits/favorite/manage_fav_cubit.dart';
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

class ItemCard extends StatefulWidget {
  const ItemCard({
    required this.item,
    this.aspectRatio = 3 / 2,
    this.width,
    this.bigCard,
    this.onTap,
    super.key,
  });

  final double? width;
  final bool? bigCard;
  final ItemModel? item;
  final VoidCallback? onTap;
  final double aspectRatio;

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  double likeButtonSize = 32;

  Widget _buildTypeIndicator(BuildContext context) {
    String? type = widget.item?.category?.categoryType;

    if (type == 'donation') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.red, size: 14),
          const SizedBox(width: 2),
          CustomText(
            'free'.translate(context),
            fontSize: context.font.small,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ],
      );
    } else if (type == 'swip') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz, color: Colors.blue, size: 14),
          const SizedBox(width: 2),
          Expanded(
            child: CustomText(
              'Wants to swap for : ${widget.item?.swipTitle ?? ''}',
              fontSize: context.font.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      // classic أو أي نوع آخر
      return UiUtils.getPriceWidget(widget.item!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? type = widget.item?.category?.categoryType;
    bool isSwip = type == 'swip';
    bool isDonation = type == 'donation';

    return AdaptiveContainer(
      aspectRatio: widget.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTap: () {
              widget.onTap?.call();
              Navigator.pushNamed(
                context,
                Routes.adDetailsScreen,
                arguments: {"model": widget.item},
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.color.textLightColor.withValues(alpha: 0.13),
                  width: 1,
                ),
                color: context.color.secondaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .6,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // الصورة الرئيسية
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: UiUtils.getImage(
                              widget.item?.image ?? "",
                              height: 300,
                              width: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // صورة المقايضة (تظهر فقط إذا كان الإعلان مقايضة)
                        if (isSwip && widget.item?.swipImage != null)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: UiUtils.getImage(
                                  widget.item!.swipImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        if (widget.item?.isFeature ?? false)
                          const PositionedDirectional(
                            start: 10,
                            top: 5,
                            child: PromotedCard(type: PromoteCardType.icon),
                          ),
                        favButton(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypeIndicator(context),
                          CustomText(
                            widget.item!.translatedName!,
                            fontSize: context.font.large,
                            maxLines: 1,
                            firstUpperCaseWidget: true,
                          ),
                          if (widget.item?.translatedAddress != "")
                            Row(
                              children: [
                                UiUtils.getSvg(
                                  AppIcons.location,
                                  width: widget.bigCard == true ? 10 : 8,
                                  height: widget.bigCard == true ? 13 : 11,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(start: 3.0),
                                    child: CustomText(
                                      UiUtils.formatDisplayAddress(
                                        widget.item?.translatedAddress ?? '',
                                      ),
                                      fontSize: (widget.bigCard == true)
                                          ? context.font.small
                                          : context.font.smaller,
                                      color: context.color.textDefaultColor
                                          .withValues(alpha: 0.5),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (widget.item?.created != "")
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: widget.bigCard == true ? 12 : 10,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(start: 3.0),
                                    child: CustomText(
                                      timeago.format(
                                        DateTime.parse(widget.item!.created!),
                                        locale: Constant.currentLocale,
                                      ),
                                      fontSize: (widget.bigCard == true)
                                          ? context.font.small
                                          : context.font.smaller,
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
          );
        },
      ),
    );
  }

  Widget favButton() {
    bool isLike = context.read<FavoriteCubit>().isItemFavorite(
      widget.item!.id!,
    );

    return BlocConsumer<FavoriteCubit, FavoriteState>(
      bloc: context.read<FavoriteCubit>(),
      listener: (context, state) {
        if (state is FavoriteFetchSuccess) {
          setState(() {});
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
            return PositionedDirectional(
              bottom: 2,
              end: 4,
              child: InkWell(
                onTap: () {
                  UiUtils.checkUser(
                    onNotGuest: () {
                      context.read<UpdateFavoriteCubit>().setFavoriteItem(
                        item: widget.item!,
                        type: isLike ? 0 : 1,
                      );
                    },
                    context: context,
                  );
                },
                child: Container(
                  width: likeButtonSize,
                  height: likeButtonSize,
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    shape: BoxShape.circle,
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
              ),
            );
          },
        );
      },
    );
  }
}

class AdaptiveDimensions {
  final double width;
  final double height;

  AdaptiveDimensions(this.width, this.height);

  @override
  String toString() =>
      'Width: ${width.toStringAsFixed(1)}, Height: ${height.toStringAsFixed(1)}';
}

class DimensionCalculator {
  static AdaptiveDimensions calculate({
    required double availableWidth,
    required double availableHeight,
    required double aspectRatio, // width/height (e.g., 16/9 = 1.777)
    required double minWidth,
    required double maxWidth,
    required double minHeight,
    required double maxHeight,
  }) {
    // Calculate dimensions based on aspect ratio
    // Try width-based calculation first
    double width = availableWidth;
    double height = width / aspectRatio;

    // If height exceeds available space, calculate from height instead
    if (height > availableHeight) {
      height = availableHeight;
      width = height * aspectRatio;
    }

    // Apply constraints while maintaining aspect ratio
    // Check width constraints
    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspectRatio;
    } else if (width < minWidth) {
      width = minWidth;
      height = width / aspectRatio;
    }

    // Check height constraints and adjust if needed
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    } else if (height < minHeight) {
      height = minHeight;
      width = height * aspectRatio;
    }

    // Final validation - if still out of bounds, prioritize fitting within constraints
    // even if it means slightly breaking aspect ratio
    width = width.clamp(minWidth, maxWidth);
    height = height.clamp(minHeight, maxHeight);

    return AdaptiveDimensions(width, height);
  }
}

// Usage in a widget:
class AdaptiveContainer extends StatelessWidget {
  final double aspectRatio;
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const AdaptiveContainer({
    Key? key,
    required this.aspectRatio,
    this.minWidth = 100,
    this.maxWidth = double.infinity,
    this.minHeight = 100,
    this.maxHeight = double.infinity,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = DimensionCalculator.calculate(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
          aspectRatio: aspectRatio,
          minWidth: minWidth,
          maxWidth: maxWidth,
          minHeight: minHeight,
          maxHeight: maxHeight,
        );

        return SizedBox(
          width: dimensions.width,
          height: dimensions.height,
          child: child,
        );
      },
    );
  }
}
