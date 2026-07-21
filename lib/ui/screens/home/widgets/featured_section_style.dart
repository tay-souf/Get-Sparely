abstract class FeaturedSectionStyles {
  static FeaturedSectionStyleData? styleFromName(String? name) {
    return _sectionMap[name];
  }

  static final _sectionMap = {
    'style_1': FeaturedSectionStyleData(
      type: SectionType.list,
      childAspectRatio: 1.1,
    ),
    'style_2': FeaturedSectionStyleData(
      type: SectionType.list,
      childAspectRatio: .7,
    ),
    'style_3': FeaturedSectionStyleData(
      type: SectionType.grid,
      childAspectRatio: .7,
    ),
    'style_4': FeaturedSectionStyleData(
      type: SectionType.list,
      childAspectRatio: .9,
    ),
  };
}

enum SectionType { list, grid }

class FeaturedSectionStyleData {
  const FeaturedSectionStyleData({
    required this.type,
    required this.childAspectRatio,
  });

  final SectionType type;
  final double childAspectRatio;

  @override
  String toString() {
    return 'FeaturedSectionStyleData{type: $type, childAspectRatio: $childAspectRatio}';
  }
}
