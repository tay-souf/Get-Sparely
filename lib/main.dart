import 'package:eClassify/app/app.dart';
import 'package:eClassify/app/app_localization.dart';
import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/register_cubits.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/language_cubit.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/globals.dart';
import 'package:eClassify/ui/screens/onboarding/widgets/onboarding_page_view.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/notification/awsome_notification.dart';
import 'package:eClassify/utils/notification/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => initApp();

class SparelyEntryPoint extends StatefulWidget {
  const SparelyEntryPoint({super.key});

  @override
  SparelyEntryPointState createState() => SparelyEntryPointState();
}

class SparelyEntryPointState extends State<SparelyEntryPoint> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: RegisterCubits().providers,
      child: const SparelyMainApp(),
    );
  }
}

class SparelyMainApp extends StatefulWidget {
  const SparelyMainApp({super.key});

  @override
  State<SparelyMainApp> createState() => _SparelyMainAppState();
}

class _SparelyMainAppState extends State<SparelyMainApp> {
  @override
  void initState() {
    super.initState();
    LocalAwesomeNotification().init();
    NotificationService.init(context);
    FirebaseMessaging.onBackgroundMessage(
      NotificationService.onBackgroundMessageHandler,
    );
    ChatGlobals.init();
    context.read<LanguageCubit>().loadCurrentLanguage();

    if (HiveUtils.isUserFirstTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final data in kSlidersList) {
          final assetName = data['svg'] as String;
          final loader = SvgAssetLoader(assetName);
          svg.cache.putIfAbsent(
            loader.cacheKey(null),
            () => loader.loadBytes(null),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppTheme currentTheme = context.watch<AppThemeCubit>().state;
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return MaterialApp(
          initialRoute: Routes.splash,
          navigatorKey: Constant.navigatorKey,
          title: Constant.appName,
          debugShowCheckedModeBanner: false,
          onGenerateRoute: Routes.onGenerateRouted,
          theme: appThemeData[currentTheme],
          builder: (context, child) {
            TextDirection direction = TextDirection.ltr;

            if (languageState is LanguageLoader) {
              direction = languageState.language['rtl']
                  ? TextDirection.rtl
                  : TextDirection.ltr;
            }
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: Directionality(textDirection: direction, child: child!),
            );
          },
          localizationsDelegates: const [
            AppLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: loadLocalLanguageIfFail(languageState),
        );
      },
    );
  }

  dynamic loadLocalLanguageIfFail(LanguageState state) {
    if ((state is LanguageLoader)) {
      return Locale(state.language['code']);
    } else if (state is LanguageLoadFail) {
      return const Locale("en");
    }
  }
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
