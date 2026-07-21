import 'dart:io';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ManageItemType { add, edit, delete }

abstract class ManageItemState {}

class ManageItemInitial extends ManageItemState {}

class ManageItemInProgress extends ManageItemState {}

class ManageItemSuccess extends ManageItemState {
  final ManageItemType type;
  final ItemModel model;

  ManageItemSuccess(this.model, this.type);
}

class ManageItemFail extends ManageItemState {
  final dynamic error;

  ManageItemFail(this.error);
}

class ManageItemCubit extends Cubit<ManageItemState> {
  ManageItemCubit() : super(ManageItemInitial());
  final ItemRepository _itemRepository = ItemRepository();

  void manage(
      ManageItemType type,
      Map<String, dynamic> data,
      File? mainImage,
      File? swipImage,
      List<File>? otherImage,
      ) async {
    try {
      emit(ManageItemInProgress());

      if (type == ManageItemType.add) {
        // mainImage يجب أن يكون غير nullable للإضافة
        if (mainImage == null) {
          throw Exception("Main image is required for adding item");
        }
        ItemModel itemModel = await _itemRepository.createItem(
          data,
          mainImage,
          otherImage,
          swipImage: swipImage,
        );
        emit(ManageItemSuccess(itemModel, type));
      } else if (type == ManageItemType.edit) {
        ItemModel itemModel = await _itemRepository.editItem(
          data,
          mainImage,
          otherImage,
          swipImage: swipImage,
        );
        print('swipImage in cubit: ${swipImage?.path}');
        emit(ManageItemSuccess(itemModel, type));
      }
    } catch (e) {
      emit(ManageItemFail(e));
    }
  }
}