// lib/core/network/api_config.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  final String serverRoot; // e.g. http://192.168.1.9:8080
  final String baseUrl; // e.g. http://192.168.1.9:8080/api
  final Map<String, dynamic> extras;

  ApiConfig._(this.serverRoot, this.baseUrl, this.extras);

  static const _prefsKey = 'api_root';
  static const _dartDefineDefault =
      String.fromEnvironment('API_ROOT', defaultValue: 'http://10.0.2.2:8080');

  static Future<ApiConfig> load() async {
    String? fromPrefs;
    try {
      final sp = await SharedPreferences.getInstance();
      final v = sp.getString(_prefsKey);
      if (v != null && v.trim().isNotEmpty) fromPrefs = v.trim();
    } catch (_) {}

    Map<String, dynamic> json = const {};
    String? fromJson;
    try {
      final raw = await rootBundle.loadString('lib/config/hostIp.json');
      json = jsonDecode(raw) as Map<String, dynamic>;
      final candidate =
          (json['serverURI'] ?? json['serverUrl'] ?? '').toString();
      if (candidate.trim().isNotEmpty) fromJson = candidate.trim();
    } catch (_) {}

    final root = _normalize(fromPrefs ?? fromJson ?? _dartDefineDefault);
    return ApiConfig._(root, '$root/api', json);
  }

  /// Config built without touching shared preferences or the asset bundle.
  ///
  /// Last-resort fallback for when [load] fails or takes too long: a wrong
  /// base URL still gives a usable app shell, whereas an uninitialised Dio
  /// throws on the first build and leaves the user staring at the splash.
  static ApiConfig fallback() {
    final root = _normalize(_dartDefineDefault);
    return ApiConfig._(root, '$root/api', const {});
  }

  static String _normalize(String input) {
    var s = input.trim();
    if (s.endsWith('/api')) s = s.substring(0, s.length - 4);
    s = s.replaceAll(RegExp(r'/+$'), '');
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          s = s
              .replaceFirst('http://localhost', 'http://10.0.2.2')
              .replaceFirst('https://localhost', 'http://10.0.2.2');
        }
      } catch (_) {}
    }
    return s;
  }
}
