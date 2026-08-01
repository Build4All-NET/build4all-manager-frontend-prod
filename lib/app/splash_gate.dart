import 'dart:convert';

import 'package:build4all_manager/core/bootstrap/app_bootstrap.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/notifications/firebase_push_service.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/shared/widgets/app_loading_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  /// A silent-refresh round trip should be quick. If the backend is slow or
  /// unreachable we fall back to the login screen rather than parking the user
  /// on a spinner for a full 60s receive timeout.
  static const Duration _refreshTimeout = Duration(seconds: 12);

  /// Push registration is optional, so we only wait a bounded time for the
  /// background Firebase init to report in.
  static const Duration _firebaseWait = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final store = JwtLocalDataSource();
    final api = AuthApi(DioClient.ensure());

    final (token, roleRaw) = await store.read();
    final refresh = (await store.readRefreshToken())?.trim() ?? '';

    if (!mounted) return;

    final role = roleRaw.trim().toUpperCase();

    if (role.isEmpty) {
      DioClient.clearToken();
      context.go('/login');
      return;
    }

    String access = token.trim();

    if (access.isEmpty || _isJwtExpired(access)) {
      if (refresh.isEmpty) {
        await store.clear();
        DioClient.clearToken();

        if (!mounted) return;
        context.go('/login');
        return;
      }

      try {
        final res = await api.refresh(refresh).timeout(_refreshTimeout);
        final data = res.data;

        if (data is! Map) {
          throw Exception('BAD_REFRESH_RESPONSE');
        }

        final newToken = (data['token'] ?? '').toString().trim();
        final newRefresh = (data['refreshToken'] ?? '').toString().trim();

        if (newToken.isEmpty || newRefresh.isEmpty) {
          throw Exception('MISSING_TOKENS');
        }

        await store.save(
          token: newToken,
          role: role,
          refreshToken: newRefresh,
        );

        DioClient.setToken(newToken);
        access = newToken;
      } catch (e, st) {
        debugPrint('Splash refresh failed: $e');
        debugPrint('$st');

        final shouldClear = _shouldClearAfterRefreshFailure(e);

        if (shouldClear) {
          await store.clear();
          DioClient.clearToken();
        }

        if (!mounted) return;
        context.go('/login');
        return;
      }
    } else {
      DioClient.setToken(access);
    }

    if (!mounted) return;
    context.go(role == 'SUPER_ADMIN' ? '/manager' : '/owner');

    Future.microtask(() async {
      try {
        // Firebase now boots in the background (see AppBootstrap), so it may
        // not be ready yet — touching FirebaseMessaging before it is would
        // throw "No Firebase App '[DEFAULT]' has been created".
        final ready = await AppBootstrap.firebaseReady
            .timeout(_firebaseWait, onTimeout: () => false);

        if (!ready) {
          debugPrint('Push init skipped: Firebase not available');
          return;
        }

        await FirebasePushService()
            .initForAdmin()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Push init from SplashGate failed or timed out: $e');
      }
    });
  }

  bool _shouldClearAfterRefreshFailure(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;

      if (status == 401 || status == 403) {
        return true;
      }

      return false;
    }

    final msg = e.toString().toUpperCase();

    return msg.contains('NO_REFRESH') ||
        msg.contains('BAD_REFRESH') ||
        msg.contains('BAD_REFRESH_RESPONSE') ||
        msg.contains('MISSING_TOKENS') ||
        msg.contains('REFRESH TOKEN') ||
        msg.contains('INVALID_REFRESH');
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);

      if (map is! Map) return true;

      final exp = map['exp'];
      if (exp == null) return true;

      final expSeconds =
          (exp is num) ? exp.toInt() : int.parse(exp.toString());
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return nowSeconds >= expSeconds;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView(message: 'Signing you in…');
  }
}