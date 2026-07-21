import 'dart:async';
import 'dart:developer';

import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/repositories/location/location_repository.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef LocationDeniedCallback =
    void Function(LocationPermission permission, bool isLocationServiceEnabled);

final class LocationUtility {
  factory LocationUtility() => _instance;

  LocationUtility._internal();

  static final LocationUtility _instance = LocationUtility._internal();

  static final _repo = LocationRepository();

  static LeafLocation? _location;

  LeafLocation? get location => _location;

  set location(LeafLocation? location) {
    // This will only check the reference in memory and not the actual content which
    // is not ideal way, but we keep it like this just for the sake of it as
    // this does not have any downside.
    // Todo(rio): override == in LeafLocation to have better equality
    if (location == _location) return;
    _location = location;
  }

  Future<LocationPermission> _getLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  Future<LeafLocation?> getLocation({
    LocationDeniedCallback? onPermissionDenied,
  }) async {
    final permission = await _getLocationPermission();
    final permissionGiven =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (permissionGiven && locationServiceEnabled) {
      await _getLiveLocation();
      return location;
    } else {
      onPermissionDenied?.call(permission, locationServiceEnabled);
    }
    return null;
  }

  Future<void> _getLiveLocation() async {
    // This will require user to manually tap the my location button to get the current location
    // instead of directly fetching it when the controller is ready.
    // TODO(rio): Refactor this to use last known location during the initial load and immediately fetch the current location once the controller is ready
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          timeLimit: const Duration(seconds: 30),
        ),
      );
    } on TimeoutException catch (_) {
      position = await Geolocator.getLastKnownPosition();
    } on Exception catch (e, stack) {
      log('$e', name: '_getLiveLocation');
      log('$stack', name: '_getLiveLocation');
    }
    if (position == null) {
      _getPersistedLocation();
    } else {
      bool shouldFetch = true;
      if (location?.hasCoordinates ?? false) {
        final newCoordinates = LatLng(position.latitude, position.longitude);
        final oldCoordinates = LatLng(
          location!.latitude!,
          location!.longitude!,
        );
        shouldFetch = _shouldReFetch(oldCoordinates, newCoordinates);
      }
      if (shouldFetch) {
        location = await getLeafLocationFromLatLng(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    }
  }

  /// Determines whether the location is far enough from the previous one
  /// to justify re-fetching data from the server.
  ///
  /// This helps avoid unnecessary API calls if the user hasn't moved much,
  /// especially when spamming the "my location" button.
  ///
  /// Returns `true` if the distance between [oldCoordinates] and [newCoordinates]
  /// is greater than 3 km.
  bool _shouldReFetch(LatLng oldCoordinates, LatLng newCoordinates) {
    final distance = Geolocator.distanceBetween(
      oldCoordinates.latitude,
      oldCoordinates.longitude,
      newCoordinates.latitude,
      newCoordinates.longitude,
    );

    return distance > 3000;
  }

  void _getPersistedLocation() {
    location = HiveUtils.getLocation() ?? Constant.defaultLocation;
  }

  Future<LeafLocation> getLeafLocationFromLatLng({
    required double latitude,
    required double longitude,
  }) async {
    return await _repo.getLocationFromLatLng(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
