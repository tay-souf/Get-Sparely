import 'dart:developer';

import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ItemListState {}

class ItemListInitial extends ItemListState {}

class ItemListLoading extends ItemListState {}

class ItemListSuccess extends ItemListState {
  ItemListSuccess({required this.items});

  final List<ItemModel> items;
}

class ItemListFailure extends ItemListState {
  ItemListFailure({required this.errorMessage});

  final String errorMessage;
}

class ItemListCubit extends Cubit<ItemListState> {
  ItemListCubit() : super(ItemListInitial());

  final ItemRepository _repository = ItemRepository();

  int page = 1;
  bool hasMore = true;

  Future<void> getItemList({required ItemMetaData metadata}) async {
    try {
      emit(ItemListLoading());
      page = 1;
      hasMore = false;
      final result = await _repository.getItem(metadata: metadata, page: page);

      hasMore = result['has_more'] as bool;

      emit(ItemListSuccess(items: result['data'] as List<ItemModel>));
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'getItemList');
      log('$stack', name: 'getItemList');
      emit(ItemListFailure(errorMessage: e.toString()));
    }
  }

  Future<void> loadMoreItems({required ItemMetaData metadata}) async {
    if (state is! ItemListSuccess) return;
    if (!hasMore) return;
    hasMore = false;
    log('Fetching more items');
    try {
      final result = await _repository.getItem(
        metadata: metadata,
        page: page + 1,
      );
      hasMore = result['has_more'] as bool;
      emit(
        ItemListSuccess(
          items: [
            ...(state as ItemListSuccess).items,
            ...result['data'] as List<ItemModel>,
          ],
        ),
      );
      ++page;
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'loadMoreItems');
      log('$stack', name: 'loadMoreItems');
    }
  }
}
