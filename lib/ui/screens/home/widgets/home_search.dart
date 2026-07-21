import 'dart:convert';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_keys.dart' show HiveKeys;
import 'package:eClassify/utils/json_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          final history = Hive.box(HiveKeys.historyBox).values.map((
            jsonString,
          ) {
            final json = (jsonDecode(jsonString) as Map)
                .cast<String, dynamic>();
            return JsonHelper.parseObject(json, ItemModel.fromJson);
          }).toList();

          Navigator.pushNamed(
            context,
            Routes.itemsList,
            arguments: SearchMetaData(
              title: 'search'.translate(context),
              searchHistory: history,
            ),
          );
        },
        child: IgnorePointer(
          ignoring: true,
          child: TextField(
            autofocus: false,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.color.textLightColor),
              ),
              hintText: 'searchHintLbl'.translate(context),
              hintStyle: TextStyle(color: context.color.textLightColor),
              prefixIcon: Icon(
                Icons.search,
                color: context.color.territoryColor,
              ),
              prefixIconConstraints: BoxConstraints.tight(Size.square(38)),
              constraints: BoxConstraints(maxHeight: 48),
            ),
          ),
        ),
      ),
    );
  }
}
