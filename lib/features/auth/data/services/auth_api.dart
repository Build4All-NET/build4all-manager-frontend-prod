import 'package:dio/dio.dart';
import '../models/login_request_dto.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<Response> login(LoginRequestDto body) {
    return _dio.post('/auth/admin/login', data: body.toJson());
  }

  Future<Response> ownerSendOtp({
    required String email,
    required String password,
  }) {
    return _dio.post(
      '/auth/owner/send-verification-email',
      queryParameters: {
        'email': email,
        'password': password,
      },
    );
  }

Future<Response> reactivateAdminDeletion({
  required String identifier,
  required String password,
}) {
  return _dio.post(
    '/auth/admin/reactivate-deletion',
    data: {
      'identifier': identifier.trim(),
      'password': password,
    },
  );
}

  Future<Response> refresh(String refreshToken) {
    return _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken.trim()},
    );
  }

  Future<Response> logout({required String refreshToken}) {
    return _dio.post(
      '/auth/logout',
      data: {'refreshToken': refreshToken.trim()},
    );
  }

  Future<Response> ownerVerifyOtp({
    required String email,
    required String password,
    required String code,
  }) {
    return _dio.post(
      '/auth/owner/verify-email-code',
      data: {
        'email': email,
        'password': password,
        'code': code,
      },
    );
  }

  Future<Response> ownerForgotPasswordSendCode({required String email}) {
    return _dio.post(
      '/auth/owner/forgot-password/send-code',
      queryParameters: {'email': email},
    );
  }

  Future<Response> ownerForgotPasswordVerifyCode({
    required String email,
    required String code,
  }) {
    return _dio.post(
      '/auth/owner/forgot-password/verify-code',
      data: {
        'email': email,
        'code': code,
      },
    );
  }

  Future<Response> ownerForgotPasswordReset({
    required String resetToken,
    required String newPassword,
  }) {
    return _dio.post(
      '/auth/owner/forgot-password/reset',
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
  }

  Future<Response> ownerCompleteProfile({
    required String registrationToken,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    int? countryId,
  }) {
    return _dio.post(
      '/auth/owner/complete-profile',
      data: {
        'registrationToken': registrationToken,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        if (countryId != null) 'countryId': countryId,
      },
    );
  }
}