import 'dart:async';

import 'package:eClassify/data/cubits/location/leaf_location_cubit.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/ui/screens/location/helpers/location_dialog.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/location_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

/// A mixin that handles location resolution for the root/home screen of the app.
///
/// This mixin provides automatic location detection and permission handling
/// for screens that need to know the user's current location. It manages:
/// - Location permission requests
/// - Location service status monitoring
/// - Location fetching with fallback to default location
/// - Dialog presentation for permission/service issues
/// - Lifecycle-aware location updates
///
/// The mixin automatically cancels location operations when the widget
/// is disposed and handles app lifecycle changes appropriately.
///
/// REQUIRES:
/// - A widget that extends `StatefulWidget`
/// - A `State` class that extends `State<T>` where `T` is the widget type
/// - The `State` class must implement `WidgetsBindingObserver`
///
/// Usage:
/// ```dart
/// class HomeScreen extends StatefulWidget {
///   @override
///   State<HomeScreen> createState() => _HomeScreenState();
/// }
///
/// class _HomeScreenState extends State<HomeScreen> with RootLocationResolverMixin<HomeScreen> {
///   // The mixin will automatically handle location resolution
/// }
/// ```
mixin RootLocationResolverMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  /// Controls whether location should be fetched.
  /// Set to false when location is successfully obtained or when user denies permission.
  bool _shouldFetchLocation = true;

  /// Tracks if a location permission/service dialog is currently shown.
  /// Prevents multiple dialogs from appearing simultaneously.
  bool _isDialogActive = false;

  /// Subscription to location service status changes (enabled/disabled).
  /// Used to re-trigger location fetching when service becomes available.
  late final StreamSubscription<ServiceStatus> _serviceStatusStream;

  /// Initializes the mixin by:
  /// - Adding this as a lifecycle observer to monitor app state changes
  /// - Setting up a stream listener for location service status changes
  /// - Attempting to fetch location if conditions are met
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen(
      (status) => _shouldFetchLocation = status == ServiceStatus.enabled,
    );

    _maybeCallGetLocation();
  }

  /// Handles app lifecycle state changes.
  /// When the app is resumed and location should be fetched, attempts to get location.
  /// Also closes any active location dialogs when the app resumes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _shouldFetchLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getLocation();
        if (_isDialogActive) {
          Navigator.of(context).pop();
          _isDialogActive = false;
        }
      });
    }
  }

  /// Cleans up resources when the widget is disposed.
  /// Removes the lifecycle observer and cancels the location service status stream subscription.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _serviceStatusStream.cancel();
    super.dispose();
  }

  /// Conditionally attempts to get location on initialization.
  ///
  /// This method addresses an edge case where `didChangeAppLifecycleState` alone is not
  /// sufficient to trigger a location fetch. If a user manually grants notification
  /// permissions through the device settings, the app will resume, but the lifecycle
  /// change might not trigger `_getLocation` because no permission prompt was shown.
  ///
  /// By calling this from `initState`, we ensure that if notification permissions are
  /// already granted at startup, we proceed to fetch the location, thus fixing a
  /// potential bug where location is never determined.
  void _maybeCallGetLocation() async {
    final notificationPermission = await Permission.notification.status;
    if (notificationPermission == PermissionStatus.granted &&
        _shouldFetchLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getLocation();
      });
    }
  }

  /// Attempts to get the user's current location.
  ///
  /// This method:
  /// - Sets _shouldFetchLocation to false to prevent duplicate requests
  /// - Checks if location is already available in the LeafLocationCubit
  /// - If no location exists, uses LocationUtility to fetch location
  /// - Handles permission denied scenarios by either setting default location
  ///   or showing a location dialog for user intervention
  /// - Sets the location in the cubit if successfully obtained
  void _getLocation() async {
    _shouldFetchLocation = false;
    final location = context.read<LeafLocationCubit>().state;
    if (location == null) {
      final location = await LocationUtility().getLocation(
        onPermissionDenied: (permission, isLocationServicesEnabled) {
          print('Permission Denied: $permission $isLocationServicesEnabled');
          if (permission == LocationPermission.denied) {
            _setLocation(Constant.defaultLocation);
          } else {
            _shouldFetchLocation =
                permission == LocationPermission.deniedForever;
            _isDialogActive = true;
            LocationDialog.show(
              context,
              permission: permission,
              isLocationServiceEnabled: isLocationServicesEnabled,
              onCancel: () {
                _shouldFetchLocation = false;
                _isDialogActive = false;
                _setLocation(Constant.defaultLocation);
              },
              onAccept: () {
                _isDialogActive = false;
              },
            );
          }
        },
      );
      if (location != null) {
        print(location.toJson());
        _setLocation(location);
      }
    }
  }

  /// Sets the location in the LeafLocationCubit and cleans up state.
  ///
  /// This method:
  /// - Updates the location in the LeafLocationCubit
  /// - Cancels the location service status stream (no longer needed after location is set)
  /// - Resets _shouldFetchLocation to false to prevent further attempts
  /// - Resets _isDialogActive to false to allow future dialogs if needed
  void _setLocation(LeafLocation location) {
    context.read<LeafLocationCubit>().setLocation(location);
    _serviceStatusStream.cancel();
    _shouldFetchLocation = false;
    _isDialogActive = false;
  }
}
