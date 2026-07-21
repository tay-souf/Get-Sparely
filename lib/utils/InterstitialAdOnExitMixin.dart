import 'package:eClassify/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:flutter/material.dart';

mixin InterstitialAdOnExitMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AdHelper.loadInterstitialAd();
  }

  @override
  void dispose() {
    AdHelper.showInterstitialAd();
    super.dispose();
  }
}
