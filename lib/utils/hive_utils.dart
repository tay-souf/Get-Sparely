import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/data/model/user/user_model.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class HiveUtils {
  ///private constructor
  HiveUtils._();

  static String getJWT() {
    return Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.jwtToken);
  }

  static String? getUserId() {
    return Hive.box(HiveKeys.userDetailsBox).get("id").toString();
  }

  static AppTheme getCurrentTheme() {
    var current = Hive.box(HiveKeys.themeBox).get(HiveKeys.currentTheme);

    return current == "dark" ? AppTheme.dark : AppTheme.light;
  }

  static String? getCountryCode() {
    return Hive.box(HiveKeys.userDetailsBox).get("country_code");
  }

  static void setProfileNotCompleted() async {
    await Hive.box(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.isProfileCompleted, false);
  }

  static dynamic setCurrentTheme(AppTheme theme) {
    String newTheme = theme == AppTheme.light ? "light" : "dark";

    Hive.box(HiveKeys.themeBox).put(HiveKeys.currentTheme, newTheme);
  }

  static void setUserData(Map data) async {
    await Hive.box(HiveKeys.userDetailsBox).putAll(data);
  }

  static void setJWT(String token) async {
    await Hive.box(HiveKeys.userDetailsBox).put(HiveKeys.jwtToken, token);
  }

  static UserModel getUserDetails() {
    return UserModel.fromJson(
      Map.from(Hive.box(HiveKeys.userDetailsBox).toMap()),
    );
  }

  static void setUserIsAuthenticated(bool value) {
    Hive.box(HiveKeys.authBox).put(HiveKeys.isAuthenticated, value);
  }

  static Future<void> setUserIsNotNew() {
    return Hive.box(HiveKeys.authBox).put(HiveKeys.isUserFirstTime, false);
  }

  static Future<void> setUserSkip() {
    return Hive.box(HiveKeys.authBox).put(HiveKeys.isUserSkip, true);
  }

  static void setLocation({required LeafLocation location}) {
    final effectiveLocation = Constant.isDemoModeOn
        ? Constant.defaultLocation
        : location;
    Hive.box(
      HiveKeys.userDetailsBox,
    ).put(HiveKeys.locationKey, effectiveLocation.toJson());
  }

  static LeafLocation? getLocation() {
    final json =
        (Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.locationKey) as Map?)
            ?.cast<String, dynamic>();

    return json != null ? LeafLocation.fromJson(json) : null;
  }

  static Future<bool> storeLanguage(dynamic data) async {
    Hive.box(HiveKeys.languageBox).put(HiveKeys.currentLanguageKey, data);
    return true;
  }

  static dynamic getLanguage() {
    return Hive.box(HiveKeys.languageBox).get(HiveKeys.currentLanguageKey);
  }

  static bool isUserAuthenticated() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isAuthenticated) ?? false;
  }

  static bool isUserFirstTime() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isUserFirstTime) ?? true;
  }

  static bool isUserSkip() {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.isUserSkip) ?? false;
  }

  static Future<void> logoutUser(context, {VoidCallback? onLogout}) async {
    await Hive.box(HiveKeys.userDetailsBox).clear();
    HiveUtils.setUserIsAuthenticated(false);
    onLogout?.call();
  }

  static Future<void> clear() async {
    await Hive.box(HiveKeys.userDetailsBox).clear();
    await Hive.box(HiveKeys.historyBox).clear();
    HiveUtils.setUserIsAuthenticated(false);
  }

  static Future<bool> getHasSubscribedToTopics() async {
    return Hive.box(HiveKeys.authBox).get(HiveKeys.hasSubscribedToTopics)
            as bool? ??
        false;
  }

  static Future<void> setHasSubscribedToTopics(bool value) async {
    await Hive.box(HiveKeys.authBox).put(HiveKeys.hasSubscribedToTopics, value);
  }
}
