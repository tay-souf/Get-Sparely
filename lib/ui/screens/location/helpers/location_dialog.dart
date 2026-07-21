import 'package:eClassify/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationDialog {
  static Future<void> show(
    BuildContext context, {
    required LocationPermission permission,
    required bool isLocationServiceEnabled,
    VoidCallback? onCancel,
    VoidCallback? onAccept,
  }) async {
    LoadingWidgets.hideLoader(context);

    if (permission == LocationPermission.denied) {
      _showPermissionDeniedMessage(context);
    } else if (permission == LocationPermission.deniedForever) {
      await _showPermissionDeniedForeverDialog(
        context,
        onCancel: onCancel,
        onAccept: onAccept,
      );
    } else if (!isLocationServiceEnabled) {
      await _showLocationServiceDisabledDialog(
        context,
        onCancel: onCancel,
        onAccept: onAccept,
      );
    }
  }

  static Future<void> _showPermissionDeniedForeverDialog(
    BuildContext context, {
    VoidCallback? onCancel,
    VoidCallback? onAccept,
  }) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        svgImagePath: AppIcons.locationDenied,
        title: 'locationPermissionDenied'.translate(context),
        content: CustomText('weNeedLocationAvailableLbl'.translate(context)),
        cancelButtonName: 'cancelBtnLbl'.translate(context),
        acceptButtonName: 'settingsLbl'.translate(context),
        onCancel: onCancel,
        onAccept: () {
          // This onAccept call is only used by RootLocationResolverMixin to
          // set the value of _isDialogActive to false which fixes a bug where
          // navigator pops the current route incorrectly when the dialog
          // auto closes after pressing settings button.
          onAccept?.call();
          Geolocator.openAppSettings();
          return Future.value();
        },
      ),
    );
  }

  static void _showPermissionDeniedMessage(BuildContext context) {
    HelperUtils.showSnackBarMessage(
      context,
      'locationPermissionDenied'.translate(context),
    );
  }

  static Future<void> _showLocationServiceDisabledDialog(
    BuildContext context, {
    VoidCallback? onCancel,
    VoidCallback? onAccept,
  }) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        svgImagePath: AppIcons.locationDenied,
        title: 'locationServiceDisabled'.translate(context),
        content: CustomText(
          'pleaseEnableLocationServicesManually'.translate(context),
        ),
        cancelButtonName: 'cancelBtnLbl'.translate(context),
        acceptButtonName: 'settingsLbl'.translate(context),
        onCancel: onCancel,
        onAccept: () {
          // This onAccept call is only used by RootLocationResolverMixin to
          // set the value of _isDialogActive to false which fixes a bug where
          // navigator pops the current route incorrectly when the dialog
          // auto closes after pressing settings button.
          onAccept?.call();
          Geolocator.openLocationSettings();
          return Future.value();
        },
      ),
    );
  }
}
