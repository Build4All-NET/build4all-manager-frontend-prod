import 'dart:async';

import 'package:build4all_manager/core/bootstrap/app_bootstrap.dart';
import 'package:build4all_manager/core/localization/locale_cubit.dart';
import 'package:build4all_manager/core/localization/locale_storage.dart';
import 'package:build4all_manager/core/network/connecting/connection_banner.dart';
import 'package:build4all_manager/core/network/connecting/connection_cubit.dart';
import 'package:build4all_manager/core/network/connecting/server_down_overlay.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:build4all_manager/app/router/router.dart' as nav;
import 'package:build4all_manager/features/theme_manager/data/local_theme_store.dart';
import 'package:build4all_manager/features/theme_manager/presentation/theme_cubit.dart';

Future<void> main() {
  if (!kReleaseMode) return _boot();

  // A release build must leave the console empty. Our own logging is gone, but
  // three things keep writing there on their own — and on the web every one of
  // them is a devtools tab away from any user:
  //
  //  * `debugPrint`, which the framework and plugins call directly and which
  //    is *not* stripped from release builds,
  //  * framework and uncaught async errors, dumped with a full stack trace,
  //  * a plain console call from a third-party package.
  //
  // The app ships no crash reporting, so nothing downstream needs these.
  debugPrint = (String? message, {int? wrapWidth}) {};
  FlutterError.onError = (FlutterErrorDetails details) {};
  PlatformDispatcher.instance.onError = (error, stack) => true;

  // The binding has to be initialised in the same zone that later calls
  // runApp(), so the whole boot runs inside the swallowing zone.
  return runZoned(
    _boot,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {},
    ),
  );
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only local, no-network setup is awaited here — every await before
  // runApp() is time the user spends looking at the splash screen.
  await AppBootstrap.initLocal();

  runApp(const Build4AllManagerApp());

  // Firebase / push / local notifications talk to the network and are not
  // needed to render the first screen, so they boot alongside the UI.
  unawaited(AppBootstrap.initBackgroundServices());
}

class Build4AllManagerApp extends StatelessWidget {
  const Build4AllManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(LocalThemeStore())..load()),
        BlocProvider(
          create: (_) => ConnectionCubit(),
        ),
        BlocProvider(
          create: (_) => LocaleCubit(LocaleStorage())..loadSavedLocale(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeVM>(
        builder: (context, vm) {
          return BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'Build4All Manager',
                debugShowCheckedModeBanner: false,
                theme: vm.light,
                darkTheme: vm.dark,
                themeMode: vm.mode,
                routerConfig: nav.router,
                locale: locale,
                builder: (context, child) {
                  return Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const Align(
                        alignment: Alignment.topCenter,
                        child: ConnectionBanner(),
                      ),
                      const ServerDownOverlay(),
                    ],
                  );
                },
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                localeListResolutionCallback: (locales, supported) {
                  if (locales == null || locales.isEmpty) {
                    return supported.first;
                  }
                  final first = locales.first;
                  for (final s in supported) {
                    if (s.languageCode == first.languageCode) return s;
                  }
                  return supported.first;
                },
              );
            },
          );
        },
      ),
    );
  }
}
