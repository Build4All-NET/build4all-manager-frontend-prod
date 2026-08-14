import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:build4all_manager/core/config/app_boot_guard.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/notifications/local_notification_service.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/firebase_options.dart';

/// Application start-up, split into two phases.
///
/// Everything awaited before `runApp()` delays the very first frame — on the
/// web that means the user stares at the HTML splash (and previously at a
/// blank white page) for exactly that long. So the split is strict:
///
///  * [initLocal] — local-only work (asset bundle + shared preferences). It is
///    awaited before `runApp()` because the widget tree needs a configured Dio
///    instance, and it costs milliseconds.
///  * [initBackgroundServices] — Firebase, push and local notifications. These
///    hit the network (or a plugin that may not exist on this platform), so
///    they are started *after* the first frame and never block it.
class AppBootstrap {
  AppBootstrap._();

  /// Local storage / asset reads should be instant; if they are not, something
  /// is wrong and we would rather boot with defaults than hang on a splash.
  static const Duration _localStepTimeout = Duration(seconds: 5);

  static const Duration _firebaseTimeout = Duration(seconds: 20);
  static const Duration _notificationsTimeout = Duration(seconds: 10);

  static final Completer<bool> _firebaseReady = Completer<bool>();

  /// Completes with `true` once Firebase is usable, `false` if it failed.
  ///
  /// Anything that touches `Firebase*` APIs must await this first, because
  /// Firebase is no longer guaranteed to be initialised by the time the first
  /// screen is built.
  static Future<bool> get firebaseReady => _firebaseReady.future;

  /// Phase 1 — awaited before `runApp()`. Local only, no network.
  static Future<void> initLocal() async {
    try {
      await DioClient.init().timeout(_localStepTimeout);
    } catch (_) {
      // Fall through to the default Dio configuration below.
    }

    if (!DioClient.isInitialized) {
      // The widget tree calls DioClient.ensure() during its first build; an
      // uninitialised Dio there throws and leaves the user on the splash.
      DioClient.initWithDefaults();
    }

    // VERY IMPORTANT:
    // Run boot guard BEFORE restoring the token, so it cannot clear the
    // session later, after the app has already started making requests.
    try {
      await AppBootGuard.run(
        currentApiBaseUrl: DioClient.ensure().options.baseUrl,
      ).timeout(_localStepTimeout);
    } catch (_) {
      // Boot guard is best effort; keep booting with the current session.
    }

    try {
      final (token, _) =
          await JwtLocalDataSource().read().timeout(_localStepTimeout);

      if (token.trim().isNotEmpty) {
        DioClient.setToken(token.trim());
      } else {
        DioClient.clearToken();
      }
    } catch (_) {
      try {
        DioClient.clearToken();
      } catch (_) {}
    }
  }

  /// Phase 2 — started after `runApp()`, never awaited by the UI.
  static Future<void> initBackgroundServices() async {
    final firebaseOk = await _initFirebase();

    if (!_firebaseReady.isCompleted) {
      _firebaseReady.complete(firebaseOk);
    }

    try {
      await LocalNotificationService().init().timeout(_notificationsTimeout);
    } catch (_) {
      // Local notifications stay unavailable for this session.
    }

    if (!firebaseOk) return;

    try {
      _listenToForegroundMessages();
    } catch (_) {
      // Foreground messages will simply not be surfaced.
    }
  }

  static Future<bool> _initFirebase() async {
    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(_firebaseTimeout);
        return true;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp().timeout(_firebaseTimeout);
        return true;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_firebaseTimeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'Build4All Manager';

      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          'You have a new notification';

      // iOS shows foreground notifications natively via
      // setForegroundNotificationPresentationOptions; showing a local
      // notification on top would cause duplicates.
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
        try {
          await LocalNotificationService().show(title: title, body: body);
        } catch (_) {
          // Dropping a single foreground notification is acceptable.
        }
      }
    });
  }
}
