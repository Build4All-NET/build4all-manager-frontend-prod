import 'package:dio/dio.dart';

import '../auth/session_manager.dart';
import '../network/dio_client.dart';

class AuthInterceptor extends Interceptor {
  final SessionManager sessionManager;

  AuthInterceptor({
    required this.sessionManager,
  });

  bool _isAuthPath(RequestOptions o) {
    final p = o.path;
    return p.contains('/auth/refresh') ||
        p.contains('/auth/logout') ||
        p.contains('/auth/login') ||
        p.contains('/auth/admin/login') ||
        p.contains('/auth/manager/login') ||
        p.contains('/auth/superadmin/login');
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Never attach a token to (or refresh for) the auth endpoints themselves.
    if (_isAuthPath(options)) {
      return handler.next(options);
    }

    final (token, _, _) = await sessionManager.readSession();
    var t = token.trim();

    // ✅ Proactive refresh: if the access token is expired (or about to expire
    // within the leeway), refresh BEFORE sending so the request goes out
    // authenticated. This makes refresh fully silent and avoids replaying
    // non-repeatable requests (e.g. file uploads) through the 401 path.
    if (t.isNotEmpty && sessionManager.isJwtExpired(t, leewaySeconds: 30)) {
      try {
        final newToken = await sessionManager.refreshTokens();
        if (newToken != null && newToken.trim().isNotEmpty) {
          t = newToken.trim();
        }
      } catch (_) {
        // Keep the (expired) token; the reactive onError 401 path is the
        // fallback and will surface a genuine failure if refresh truly failed.
      }
    }

    if (t.isNotEmpty) {
      options.headers['Authorization'] =
          t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode ?? 0;

    if (status != 401 || _isAuthPath(err.requestOptions)) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }

    final authHeader =
        (err.requestOptions.headers['Authorization'] ?? '').toString().trim();

    if (authHeader.isEmpty) {
      return handler.next(err);
    }

    try {
      final newToken = await sessionManager.refreshTokens();

      if (newToken == null || newToken.trim().isEmpty) {
        return handler.next(err);
      }

      final retryReq = err.requestOptions;
      retryReq.extra['__retried'] = true;
      retryReq.headers['Authorization'] = 'Bearer $newToken';

      final dio = DioClient.ensure();
      final res = await dio.fetch(retryReq);

      return handler.resolve(res);
    } catch (e) {
      final shouldClear =
          sessionManager.shouldClearSessionAfterRefreshFailure(e);

      if (shouldClear) {
        await sessionManager.clearSession();
      }

      return handler.next(err);
    }
  }
}