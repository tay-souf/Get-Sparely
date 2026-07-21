import 'package:eClassify/data/model/category_model.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/utils/json_helper.dart';

class ItemFilter {
  final String? maxPrice;
  final String? minPrice;
  final CategoryModel? category;
  final String? postedSince;
  final LeafLocation? location;
  final Map<String, dynamic>? customFields;

  ItemFilter({
    this.maxPrice,
    this.minPrice,
    this.category,
    this.postedSince,
    this.location,
    this.customFields = const {},
  });

  ItemFilter copyWith({
    String? maxPrice,
    String? minPrice,
    CategoryModel? category,
    String? postedSince,
    LeafLocation? location,
    Map<String, dynamic>? customFields,
  }) {
    return ItemFilter(
      maxPrice: maxPrice ?? this.maxPrice,
      minPrice: minPrice ?? this.minPrice,
      category: category ?? this.category,
      postedSince: postedSince ?? this.postedSince,
      location: location ?? this.location,
      customFields: customFields ?? this.customFields,
    );
  }

  Json get toJson => <String, dynamic>{
    if (maxPrice != null && maxPrice!.isNotEmpty) 'max_price': maxPrice,
    if (minPrice != null && minPrice!.isNotEmpty) 'min_price': ?minPrice,
    if (category != null) 'category_id': category!.id,
    if (postedSince != null && postedSince!.isNotEmpty)
      'posted_since': postedSince,
    ...?customFields,
    ...?location?.toApiJson(),
  };
}
