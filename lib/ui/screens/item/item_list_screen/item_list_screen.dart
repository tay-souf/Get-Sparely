import 'dart:convert';
import 'dart:developer';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/item/item_list_cubit.dart';
import 'package:eClassify/data/cubits/location/leaf_location_cubit.dart';
import 'package:eClassify/data/model/item/item_list.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/ui/screens/home/widgets/item_card_widget.dart';
import 'package:eClassify/ui/screens/home/widgets/item_horizontal_card.dart';
import 'package:eClassify/ui/screens/item/item_list_screen/item_list_bottom_bar.dart';
import 'package:eClassify/ui/screens/item/item_list_screen/item_search_bar.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/collection_notifiers.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({required this.metadata, super.key});
  final ItemMetaData metadata;

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      settings: routeSettings,
      builder: (_) => BlocProvider(
        create: (_) => ItemListCubit(),
        child: ItemListScreen(
          metadata: routeSettings.arguments as ItemMetaData,
        ),
      ),
    );
  }
}

class _ItemListScreenState extends State<ItemListScreen> {
  late ItemMetaData metadata = widget.metadata;
  final ValueNotifier<ItemDisplayType> _displayType = ValueNotifier(
    ItemDisplayType.list,
  );
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);

  late final ListNotifier<ItemModel> _searchHistory = ListNotifier(
    widget.metadata is SearchMetaData
        ? (widget.metadata as SearchMetaData).searchHistory
        : [],
  );

  @override
  void initState() {
    super.initState();
    log('${metadata.filter.toJson}');
    metadata.sortBy = null;
    metadata.filter = metadata.filter.copyWith(
      location: context.read<LeafLocationCubit>().state,
    );
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent &&
            context.read<ItemListCubit>().hasMore) {
          _isLoading.value = true;
          context.read<ItemListCubit>().loadMoreItems(metadata: metadata);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchHistory.dispose();
    _isLoading.dispose();
    _scrollController.dispose();
    _displayType.dispose();
    super.dispose();
  }

  void _getItems() {
    context.read<ItemListCubit>().getItemList(metadata: metadata);
  }

  Widget _buildItemsShimmer(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: context.color.borderColor),
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        spacing: 10,
        children: [
          CustomShimmer(height: 120, width: 100),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomShimmer(width: 100, height: 10, borderRadius: 7),
              CustomShimmer(width: 150, height: 10, borderRadius: 7),
              CustomShimmer(width: 120, height: 10, borderRadius: 7),
              CustomShimmer(width: 80, height: 10, borderRadius: 7),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loaderWidget() {
    return SizedBox(
      height: kToolbarHeight,
      child: ValueListenableBuilder(
        valueListenable: _isLoading,
        builder: (context, value, child) {
          return value ? UiUtils.progress() : const SizedBox.shrink();
        },
      ),
    );
  }

  void _addItemToSearchHistory(ItemModel item) {
    if (!_searchHistory.contains(item)) {
      if (_searchHistory.length == 5) {
        _searchHistory.removeAt(0);
      }
      _searchHistory.add(item);
    }
  }

  Widget _searchHistoryWidget() {
    return ListenableBuilder(
      listenable: _searchHistory,
      builder: (context, child) {
        if (_searchHistory.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText('recentSearches'.translate(context)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.color.territoryColor,
                  ),
                  onPressed: () {
                    _searchHistory.clear();
                  },
                  child: Text('clear'.translate(context)),
                ),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 150),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _searchHistory.reversed.map((item) {
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          Routes.adDetailsScreen,
                          arguments: {'model': item},
                        );
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.refresh),
                      title: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: item.name,
                              style: TextStyle(
                                fontSize: context.font.normal,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            if (item.category != null)
                              TextSpan(
                                text:
                                    ' ${'in'.translate(context)} ${item.category?.name}',
                                style: TextStyle(
                                  fontSize: context.font.normal,
                                  fontWeight: FontWeight.bold,
                                  color: context.color.textDefaultColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final jsonMap = _searchHistory.value.map(
          (element) => jsonEncode(element.toJson()),
        );
        Hive.box(HiveKeys.historyBox)
          ..clear().then((_) => Hive.box(HiveKeys.historyBox).addAll(jsonMap));
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.color.secondaryColor,
          title: Text(
            metadata.title,
            style: TextStyle(color: context.color.textDefaultColor),
          ),
          bottom: ItemSearchBar(
            onSearch: (query) {
              metadata.search = query;
              _getItems();
            },
            displayType: _displayType,
          ),
        ),
        bottomNavigationBar: ItemListBottomBar(
          metadata: metadata,
          onSortChanged: (value) {
            metadata.sortBy = value;
            _getItems();
          },
          onFilterChanged: (filter) {
            if (filter == null) return;
            metadata.filter = filter;
            _getItems();
          },
        ),
        body: Padding(
          padding: Constant.appContentPadding,
          child: RefreshIndicator(
            onRefresh: () async => _getItems(),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (metadata is SearchMetaData) _searchHistoryWidget(),
                  BlocConsumer<ItemListCubit, ItemListState>(
                    listener: (context, state) {
                      if (state is ItemListSuccess ||
                          state is ItemListFailure) {
                        _isLoading.value = false;
                      }
                    },
                    builder: (context, state) {
                      if (state is ItemListInitial) {
                        _getItems();
                      }
                      if (state is ItemListFailure) {
                        if (state.errorMessage == 'no-internet') {
                          return const NoInternet();
                        } else {
                          return const SomethingWentWrong();
                        }
                      }
                      if (state is ItemListSuccess) {
                        if (state.items.isEmpty) {
                          return NoDataFound(onTap: _getItems);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RefreshIndicator(
                            onRefresh: () async => _getItems(),
                            child: ValueListenableBuilder(
                              valueListenable: _displayType,
                              builder: (context, value, child) {
                                return value == ItemDisplayType.list
                                    ? ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: state.items.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) =>
                                            ItemHorizontalCard(
                                              item: state.items[index],
                                              onTap: () {
                                                _addItemToSearchHistory(
                                                  state.items[index],
                                                );
                                              },
                                            ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        itemCount: state.items.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              childAspectRatio: .65,
                                              mainAxisSpacing: 15,
                                              crossAxisSpacing: 15,
                                            ),
                                        itemBuilder: (context, index) =>
                                            ItemCard(
                                              item: state.items[index],
                                              onTap: () {
                                                _addItemToSearchHistory(
                                                  state.items[index],
                                                );
                                              },
                                            ),
                                      );
                              },
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return _buildItemsShimmer(context);
                        },
                      );
                    },
                  ),
                  _loaderWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
