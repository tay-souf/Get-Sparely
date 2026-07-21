import 'dart:developer';

import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/model/location/location_node.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/json_helper.dart';

class LocationRepository {
  factory LocationRepository() => _instance;

  LocationRepository._internal();

  static final LocationRepository _instance = LocationRepository._internal();

  /// A generic method that can fetch locations for all kinds of [LocationNode]s
  /// based on the Generic Type parameter to avoid writing the same methods for each type of
  /// [LocationNode].
  ///
  /// This is also a scalable approach if additional parts are added to the location hierarchy.
  Future<Map<String, dynamic>> fetchLocation<T extends LocationNode>({
    required int? id,
    int page = 1,
  }) async {
    try {
      final endPoint = switch (T) {
        Country => Api.getCountriesApi,
        State => Api.getStatesApi,
        City => Api.getCitiesApi,
        Area => Api.getAreasApi,
        _ => throw UnsupportedError('Unsupported Type $T'),
      };

      final idKey = switch (T) {
        Country => null,
        State => Api.countryId,
        City => Api.stateId,
        Area => Api.cityId,
        _ => throw UnsupportedError('Unsupported Type $T'),
      };

      final response = await Api.get(
        url: endPoint,
        queryParameters: {if (idKey != null) idKey: id, Api.page: page},
      );

      final dataList = switch (T) {
        Country => JsonHelper.parseList(
          response['data']['data'] as List?,
          Country.fromJson,
        ),
        State => JsonHelper.parseList(
          response['data']['data'] as List?,
          State.fromJson,
        ),
        City => JsonHelper.parseList(
          response['data']['data'] as List?,
          City.fromJson,
        ),
        Area => JsonHelper.parseList(
          response['data']['data'] as List?,
          Area.fromJson,
        ),
        _ => throw UnsupportedError('Unsupported Type $T'),
      };

      return {'data': dataList, 'total': response['data']['total']};
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'fetchLocation<$T>');
      log('$stack', name: 'fetchLocation<$T>');
      throw ApiException(e.toString());
    }
  }

  /// Performs a location search using the current map provider.
  ///
  /// This method determines which API to call based on the active map provider,
  /// then extracts and returns a list of [LeafLocation] from the response.
  ///
  /// [search] is the query string entered by the user.
  Future<List<LeafLocation>> searchLocation({
    required String search,
    String? sessionToken,
  }) async {
    final usePaidApi = Constant.mapProvider != 'free_api';
    try {
      final response = await Api.get(
        url: Api.getLocationApi,
        queryParameters: {
          Api.search: search,
          'session_id': ?sessionToken,
          // We fetch locations in English using the Places API to avoid translation issues
          // with item addresses, which would otherwise increase API calls and costs.
          Api.lang: usePaidApi ? 'EN' : Constant.currentLanguageCode,
        },
        addContentLanguage: !usePaidApi,
      );

      if (usePaidApi) {
        // final data = await rootBundle.loadString('assets/search_data.json');
        // final response = jsonDecode(data) as Map<String, dynamic>;
        final predictions = (response['data']['predictions'] as List)
            .cast<Map<String, dynamic>>();
        final locations = List<LeafLocation>.empty(growable: true);
        for (final json in predictions) {
          final location = LeafLocation(
            placeId: json['place_id'] as String,
            primaryText: json['structured_formatting']['main_text'] as String,
            secondaryText:
                json['structured_formatting']['secondary_text'] as String?,
          );
          locations.add(location);
        }
        return locations;
      } else {
        final locations = JsonHelper.parseList(
          response['data'] as List?,
          LeafLocation.fromJson,
        );
        return locations;
      }
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'searchLocation');
      log('$stack', name: 'searchLocation');
      throw ApiException(e.toString());
    }
  }

  /// Resolves a [LeafLocation] from the given latitude and longitude.
  ///
  /// Similar to [searchLocation], but uses coordinates instead of text input.
  /// Chooses the appropriate API (paid or free) based on the current map provider.
  ///
  /// Typically used when the user taps "Find My Location" or selects a point on the map.
  Future<LeafLocation> getLocationFromLatLng({
    required double latitude,
    required double longitude,
  }) async {
    final usePaidApi = Constant.mapProvider != 'free_api';
    try {
      final response = await Api.get(
        url: Api.getLocationApi,
        queryParameters: {
          Api.lat: latitude,
          Api.lng: longitude,
          // We fetch locations in English using the Places API to avoid translation issues
          // with item addresses, which would otherwise increase API calls and costs.
          Api.lang: usePaidApi ? 'EN' : Constant.currentLanguageCode,
        },
        addContentLanguage: !usePaidApi,
      );
      if (usePaidApi) {
        // final data = await rootBundle.loadString('assets/data.json');
        // final response = jsonDecode(data) as Map<String, dynamic>;
        return _extractLeafLocation(
          (response['data']['results'] as List).first,
        );
      } else {
        return JsonHelper.parseJsonOrNull(
              response['data'] as Map<String, dynamic>,
              LeafLocation.fromJson,
            ) ??
            LeafLocation();
      }
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'getLocationFromLatLng');
      log('$stack', name: 'getLocationFromLatLng');
      throw ApiException(e.toString());
    }
  }

  /// Retrieves a [LeafLocation] using the provided [placeId] from Google's Places API.
  ///
  /// This method is only available when the paid API is active.
  /// It parses the response and returns a [LeafLocation].
  ///
  /// Throws an error if used with the free API provider.
  Future<LeafLocation> getLocationFromPlaceId({
    required String placeId,
    String? sessionToken,
  }) async {
    try {
      final response = await Api.get(
        url: Api.getLocationApi,
        queryParameters: {
          'place_id': placeId,
          'session_id': ?sessionToken,
          Api.lang: 'EN',
        },
        addContentLanguage: false,
      );
      // final data = await rootBundle.loadString('assets/place_id_data.json');
      // final response = jsonDecode(data) as Map<String, dynamic>;
      return _extractLeafLocation((response['data']['results'] as List).first);
    } on Exception catch (e, stack) {
      log(e.toString(), name: 'getLocationFromPlaceId');
      log('$stack', name: 'getLocationFromPlaceId');
      throw ApiException(e.toString());
    }
  }

  /// Parses a raw Google Geocoding API JSON response into a structured [LeafLocation].
  ///
  /// This method normalizes inconsistent address structures across different countries
  /// and extracts the most semantically correct values for:
  ///
  /// - **area** → Sub-city or neighborhood region
  /// - **city** → Major city, district, or administrative region
  /// - **state** → First-level administrative division (province / state / prefecture)
  /// - **country** → Country name
  ///
  /// ### 🌍 Logic Overview
  /// Google address components differ between countries.
  /// For example:
  /// - Japan and Korea use multiple `sublocality_level_*` layers (ward → neighborhood).
  /// - The UK uses `postal_town` instead of `locality`.
  /// - India often lacks `locality`, using `sublocality_level_1` / `_2` instead.
  ///
  /// To handle this, the parser defines explicit **priority lists** for both `city` and `area`,
  /// then dynamically determines the most suitable component based on available data.
  ///
  /// Once the city component type is chosen, any **equal or higher-ranked area types**
  /// are removed from the area search space — ensuring that `area` always represents
  /// a smaller or more specific region than `city`.
  ///
  /// ### 💡 Notes
  /// - `state` and `country` are typically accurate and need no special prioritization.
  /// - Street-level details (`route`, `premise`, etc.) are intentionally ignored
  ///   to keep `area` and `city` meaningful.
  ///
  /// Used internally by:
  /// - [getLocationFromLatLng]
  /// - [getLocationFromPlaceId]

  LeafLocation _extractLeafLocation(Map<String, dynamic> json) {
    final Map<String, dynamic> leafLocationJson = Map.identity();

    leafLocationJson['latitude'] = json['geometry']['location']['lat'];
    leafLocationJson['longitude'] = json['geometry']['location']['lng'];
    leafLocationJson['place_id'] = json['place_id'];

    final components =
        (json['address_components'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    // --- Collect all types once ---
    final Map<String, String> byType = {};
    for (final component in components) {
      final types = (component['types'] as List?)?.cast<String>() ?? [];
      for (final type in types) {
        byType[type] ??= component['long_name'];
      }
    }

    // --- Define hierarchical priority (high → low) ---
    const cityPriority = [
      'locality', // actual city name, ideal case
      'sublocality_level_1', // big districts (Gangnam-gu, Shibuya-ku)
      'sublocality_level_2', // mid-level subcity
      'sublocality_level_3', // small city-level locality
      'sublocality', // generic fallback
      'postal_town', // UK fallback
      'administrative_area_level_3', // county/district fallback
      'administrative_area_level_2', // metro/region fallback
    ];

    const areaPriority = [
      'sublocality_level_1', // biggest meaningful intra-city region
      'sublocality_level_2',
      'sublocality_level_3',
      'sublocality',
      'neighborhood',
      'postal_town',
    ];

    String? pickFrom(List<String> priority, Map<String, String> map) =>
        priority.firstWhere((t) => map.containsKey(t), orElse: () => '');

    // --- Step 1: Resolve City ---
    final cityType = pickFrom(cityPriority, byType);
    leafLocationJson['city'] = cityType!.isNotEmpty ? byType[cityType] : null;

    // --- Step 2: Adjust area priorities (demotion) ---
    // If city used sublocality_level_1 → area can only use lower (level_2 or neighborhood)
    // If city used sublocality → area should not use sublocality or its levels.
    final cutoffIndex = areaPriority.indexOf(cityType);
    final adjustedAreaPriority = (cutoffIndex == -1)
        ? areaPriority
        : areaPriority.sublist(cutoffIndex + 1);

    // --- Step 3: Resolve Area ---
    final areaType = pickFrom(adjustedAreaPriority, byType);
    leafLocationJson['area'] = areaType!.isNotEmpty ? byType[areaType] : null;

    // --- Step 4: State & Country ---
    leafLocationJson['state'] =
        byType['administrative_area_level_1'] ??
        byType['administrative_area_level_2'];
    leafLocationJson['country'] = byType['country'];

    return LeafLocation.fromJson(leafLocationJson);
  }
}
