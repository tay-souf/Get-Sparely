import 'dart:math';
import 'dart:ui';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/home/home_screen_section_model.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/home/widgets/featured_section_style.dart';
import 'package:eClassify/ui/screens/home/widgets/item_card_widget.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/gap.dart';
import 'package:flutter/material.dart';

class FeaturedSectionWidget extends StatelessWidget {
  const FeaturedSectionWidget({required this.section, super.key});

  final HomeScreenSection section;

  @override
  Widget build(BuildContext context) {
    final style = FeaturedSectionStyles.styleFromName(section.style);
    if (style == null ||
        section.sectionData == null ||
        section.sectionData!.isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: _SectionTemplate(
        id: section.sectionId!,
        title: section.title!,
        child: _SectionSliverChild(style: style, items: section.sectionData!),
      ),
    );
  }
}

class _SectionSliverChild extends StatelessWidget {
  const _SectionSliverChild({required this.style, required this.items});

  final FeaturedSectionStyleData style;
  final List<ItemModel> items;

  double lerpHeight({
    required double screenHeight,
    required double minHeight,
    required double maxHeight,
    required double minScreen,
    required double maxScreen,
  }) {
    // Normalize screen height to 0–1
    final t = ((screenHeight - minScreen) / (maxScreen - minScreen)).clamp(
      0.0,
      1.0,
    );

    // Lerp between min/max height
    return lerpDouble(minHeight, maxHeight, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (style.type == SectionType.list) {
      return SizedBox(
        height: lerpHeight(
          screenHeight: screenHeight,
          minHeight: 243,
          maxHeight: 285,
          minScreen: 600,
          maxScreen: 850,
        ),
        child: ListView.separated(
          itemCount: items.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return ItemCard(
              item: items[index],
              aspectRatio: style.childAspectRatio,
            );
          },
          separatorBuilder: (context, index) => 10.hGap,
        ),
      );
    } else {
      final itemCount = min(6, items.length);
      final rows = (itemCount / 2).ceilToDouble();
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 200 * rows,
          maxHeight: 260 * rows,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return ItemCard(
              key: ValueKey(items[index].id ?? index),
              item: items[index],
            );
          },
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: style.childAspectRatio,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
        ),
      );
    }
  }
}

class _SectionTemplate extends StatelessWidget {
  const _SectionTemplate({
    required this.id,
    required this.title,
    required this.child,
  });

  final int id;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomText(
                title,
                fontSize: context.font.large,
                fontWeight: FontWeight.w600,
                maxLines: 1,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                foregroundColor: context.color.textDefaultColor,
                textStyle: TextStyle(fontSize: context.font.small),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  Routes.itemsList,
                  arguments: SectionMetaData(sectionId: id, title: title),
                );
              },
              child: Text('seeAll'.translate(context)),
            ),
          ],
        ),
        child,
      ],
    );
  }
}
