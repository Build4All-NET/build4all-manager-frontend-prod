import 'package:dio/dio.dart';

import '../models/ios_internal_testing_app_summary_model.dart';
import '../models/ios_internal_testing_request_model.dart';

class OwnerIosInternalTestingApi {
  final Dio _dio;

  OwnerIosInternalTestingApi(this._dio);

  Future<IosInternalTestingRequestModel> createRequest({
    required int linkId,
    required String appleEmail,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _dio.post(
      '/owner/apps/$linkId/ios-internal-requests',
      data: {
        'appleEmail': appleEmail.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      },
    );

    final raw = _asMap(response.data);
    final requestJson = _extractRequestMap(raw);

    return IosInternalTestingRequestModel.fromJson(requestJson);
  }

  Future<IosInternalTestingRequestModel?> getLatestRequest({
    required int linkId,
  }) async {
    try {
      final response = await _dio.get(
        '/owner/apps/$linkId/ios-internal-requests/latest',
      );

      final raw = _asMap(response.data);
      final requestJson = _extractRequestMap(raw);

      return IosInternalTestingRequestModel.fromJson(requestJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<IosInternalTestingAppSummaryModel> getRequestsSummaryForApp({
    required int linkId,
  }) async {
    final response = await _dio.get(
      '/owner/apps/$linkId/ios-internal-requests',
    );

    final raw = _asMap(response.data);

    return IosInternalTestingAppSummaryModel.fromJson(raw);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);

    throw Exception(
      'Invalid response format: expected Map but got ${raw.runtimeType}',
    );
  }

  Map<String, dynamic> _extractRequestMap(Map<String, dynamic> raw) {
    final request = raw['request'];

    if (request is Map<String, dynamic>) {
      return request;
    }

    if (request is Map) {
      return Map<String, dynamic>.from(request);
    }

    return raw;
  }
}
