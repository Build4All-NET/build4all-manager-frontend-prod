import 'package:dio/dio.dart';

import '../models/woo_config_models.dart';

/// Owner-side WooCommerce store settings.
///
/// Two flavours of every call:
///
/// * the plain ones read the app from the owner's token, for when they are
///   already working inside an app;
/// * the `...ForApp(linkId:)` ones name the app explicitly, which is what the
///   creation wizard needs — it has just created an app the token does not
///   point at yet.
///
/// The consumer secret is never returned by the backend; [WooConfig] exposes
/// [WooConfig.consumerSecretSet] instead so the UI can render "configured"
/// without ever holding the value.
class WooConfigApi {
  final Dio dio;
  final String baseUrl;

  WooConfigApi({required this.dio, required this.baseUrl});

  String _apiRoot() {
    var b = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (!b.endsWith('/api')) b = '$b/api';
    return b;
  }

  String get _root => '${_apiRoot()}/owner/projects/woocommerce';

  /* ============================
     read
     ============================ */

  Future<WooConfigState> getForCurrentApp() async {
    final res = await dio.get(_root);
    return WooConfigState.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<WooConfigState> getForApp({required int linkId}) async {
    final res = await dio.get('$_root/apps/$linkId');
    return WooConfigState.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /* ============================
     validate before saving
     ============================ */

  /// Checks credentials that have not been stored yet, so the wizard can stop
  /// before creating an app that points at an unreachable store.
  Future<WooConnectionResult> testConnection({
    required String storeUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    return _connectionCall(
      () => dio.post(
        '$_root/test-connection',
        data: {
          'storeUrl': storeUrl,
          'consumerKey': consumerKey,
          'consumerSecret': consumerSecret,
        },
      ),
    );
  }

  /* ============================
     save + activate
     ============================ */

  /// Stores the credentials and switches the app to WooCommerce in one call.
  ///
  /// Single call on purpose: a save-then-activate pair can leave an app the
  /// owner believes is WooCommerce still sitting on Build4All if the second
  /// request never lands. The backend activates only when the live connection
  /// test passes, so a failure here leaves the app unchanged.
  Future<WooConfig> setupForApp({
    required int linkId,
    required String storeUrl,
    required String consumerKey,
    required String consumerSecret,
  }) async {
    final res = await dio.post(
      '$_root/apps/$linkId/setup',
      data: {
        'storeUrl': storeUrl,
        'consumerKey': consumerKey,
        'consumerSecret': consumerSecret,
        'enabled': true,
      },
    );
    return WooConfig.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Updates the stored settings of an app that is already on WooCommerce.
  ///
  /// Leave [consumerSecret] null to keep the stored one — the backend treats a
  /// blank secret as "unchanged", which is what lets the form round-trip
  /// without the UI ever seeing the real value.
  Future<WooConfig> saveForApp({
    required int linkId,
    required String storeUrl,
    required String consumerKey,
    String? consumerSecret,
  }) async {
    final res = await dio.put(
      '$_root/apps/$linkId',
      data: {
        'storeUrl': storeUrl,
        'consumerKey': consumerKey,
        if (consumerSecret != null && consumerSecret.isNotEmpty)
          'consumerSecret': consumerSecret,
      },
    );
    return WooConfig.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /* ============================
     re-test stored credentials
     ============================ */

  Future<WooConnectionResult> testForApp({required int linkId}) async {
    return _connectionCall(() => dio.post('$_root/apps/$linkId/test'));
  }

  /// The backend answers a failed check with 502 and the same result body as a
  /// success, so an unreachable store is a normal outcome to render rather
  /// than an exception to surface as a crash.
  Future<WooConnectionResult> _connectionCall(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final res = await call();
      return WooConnectionResult.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        return WooConnectionResult.fromJson(Map<String, dynamic>.from(data));
      }
      rethrow;
    }
  }
}
