import 'package:dio/dio.dart';
import 'package:build4all_manager/core/network/api_config.dart';
import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:build4all_manager/core/network/api_client.dart';

import 'global_error_interceptor.dart';
import 'server_status_controller.dart';

class DioClient {
  /// Call once in main() BEFORE runApp()
  static Future<void> init() async {
    _apply(await ApiConfig.load());
  }

  /// Synchronous fallback used when [init] failed or timed out, so the widget
  /// tree never has to deal with an uninitialised Dio.
  static void initWithDefaults() {
    _apply(ApiConfig.fallback());
  }

  static bool get isInitialized => g.appDio != null;

  static void _apply(ApiConfig cfg) {
    // baseUrl: http://host:8080/api
    g.appServerRoot = cfg.baseUrl;

    // init server status controller (for popup auto-retry)
    ServerStatusController.init(baseUrl: cfg.baseUrl);

    final client = ApiClient(cfg);
    g.appDio = client.dio;

    // A late-resolving ApiConfig.load() can replace the fallback client after
    // the token was already restored; carry the header over so the session
    // does not silently drop.
    final existingToken = g.authToken;
    if (existingToken != null && existingToken.isNotEmpty) {
      client.dio.options.headers['Authorization'] = 'Bearer $existingToken';
    }

    // add global interceptor once
    final dio = ensure();
    final alreadyAdded =
        dio.interceptors.any((i) => i is GlobalErrorInterceptor);

    if (!alreadyAdded) {
      dio.interceptors.add(GlobalErrorInterceptor());
    }
  }

  static Dio ensure() {
    final dio = g.appDio;
    if (dio == null) {
      throw StateError('Dio not initialized. Call DioClient.init() in main().');
    }
    return dio;
  }

  static void setToken(String token) {
    final cleaned = token.trim();
    ensure().options.headers['Authorization'] = 'Bearer $cleaned';
    g.authToken = cleaned;
  }

  static void clearToken() {
    ensure().options.headers.remove('Authorization');
    g.authToken = null;
  }
}