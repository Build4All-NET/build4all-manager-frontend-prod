import 'package:build4all_manager/core/auth/session_manager.dart';
import 'package:build4all_manager/core/network/api_config.dart';
import 'package:build4all_manager/core/network/auth_interceptor.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(ApiConfig config)
      : dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    final jwtStore = JwtLocalDataSource();
    final authApi = AuthApi(dio);
    final sessionManager = SessionManager(
      store: jwtStore,
      authApi: authApi,
    );

    dio.interceptors.add(
      AuthInterceptor(
        sessionManager: sessionManager,
      ),
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer ${token.trim()}';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}