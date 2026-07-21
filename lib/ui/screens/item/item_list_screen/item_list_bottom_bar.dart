import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/item/item_filter.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ItemListBottomBar extends StatelessWidget {
  const ItemListBottomBar({
    required this.metadata,
    required this.onSortChanged,
    required this.onFilterChanged,
    super.key,
  });

  final ItemMetaData metadata;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<ItemFilter?> onFilterChanged;

  void _showSortByBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: context.color.secondaryColor,
      builder: (context) {
        return Padding(
          padding: MediaQuery.paddingOf(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Sort.values
                .map(
                  (sort) => ListTile(
                    onTap: () {
                      onSortChanged(sort.value);
                      Navigator.of(context).pop();
                    },
                    title: Text(sort.label.translate(context)),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomNavHeight = kBottomNavigationBarHeight;
    if (Platform.isIOS) {
      bottomNavHeight += MediaQuery.paddingOf(context).bottom;
    }
    return SafeArea(
      bottom: Platform.isAndroid,
      child: SizedBox(
        height: bottomNavHeight,
        child: ColoredBox(
          color: context.color.secondaryColor,
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.color.textDefaultColor,
                  ),
                  onPressed: () async {
                    final filter =
                        await Navigator.of(context).pushNamed(
                              Routes.filterScreen,
                              arguments: {
                                'filter': metadata.filter,
                                'showCategoryDropdown':
                                    metadata is! CategoryMetaData,
                                if (metadata
                                    case CategoryMetaData categoryMetaData)
                                  ...categoryMetaData.additionalValuesForFilter,
                              },
                            )
                            as ItemFilter?;
                    onFilterChanged(filter);
                  },
                  icon: SvgPicture.asset(
                    AppIcons.filterByIcon,
                    colorFilter: ColorFilter.mode(
                      context.color.inverseThemeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text('filterTitle'.translate(context)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: context.color.textDefaultColor,
                  ),
                  onPressed: () => _showSortByBottomSheet(context),
                  icon: SvgPicture.asset(
                    AppIcons.sortByIcon,
                    colorFilter: ColorFilter.mode(
                      context.color.inverseThemeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text('sortBy'.translate(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
