import 'dart:io';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebasePushService {
  FirebasePushService._();
  static final FirebasePushService _instance = FirebasePushService._();
  factory FirebasePushService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initForAdmin() async {
    if (_initialized) {
      return;
    }

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb && Platform.isIOS) {
        // APNS token may not be ready immediately after launch; retry briefly.
        String? apnsToken;
        for (int i = 0; i < 5 && apnsToken == null; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          return;
        }
      }

      final token = await _messaging.getToken();

      if (token != null && token.trim().isNotEmpty) {
        await _sendTokenToBackend(token.trim());
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.trim().isNotEmpty) {
          await _sendTokenToBackend(newToken.trim());
        }
      });

      _initialized = true;
    } catch (_) {
      // Push notifications stay disabled for this session.
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final platform = kIsWeb
          ? 'WEB'
          : Platform.isIOS
              ? 'IOS'
              : 'ANDROID';

      await DioClient.ensure().put(
        '/notifications/admin/fcm-token',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );
    } catch (_) {
      // Token sync is best effort.
    }
  }
}
