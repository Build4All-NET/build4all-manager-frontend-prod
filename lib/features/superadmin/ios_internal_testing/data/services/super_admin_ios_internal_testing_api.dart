import 'package:dio/dio.dart';

import '../models/super_admin_ios_internal_testing_request_model.dart';

class SuperAdminIosInternalTestingApi {
  final Dio _dio;

  SuperAdminIosInternalTestingApi(this._dio);

  Future<List<SuperAdminIosInternalTestingRequestModel>> getRequests({
    String? status,
    bool manualOnly = false,
  }) async {
    final response = await _dio.get(
      '/super-admin/ios-internal-requests',
      queryParameters: {
        if (status != null && status.trim().isNotEmpty && status != 'ALL')
          'status': status.trim(),
        if (manualOnly) 'manualOnly': true,
      },
    );

    final raw = _asMap(response.data);
    final requestsRaw = raw['requests'];

    return requestsRaw is List
        ? requestsRaw
            .whereType<Map>()
            .map(
              (e) => SuperAdminIosInternalTestingRequestModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <SuperAdminIosInternalTestingRequestModel>[];
  }

  Future<SuperAdminIosInternalTestingRequestModel> processRequest(
    int requestId,
  ) async {
    final response = await _dio.post(
      '/super-admin/ios-internal-requests/$requestId/process',
    );

    final raw = _asMap(response.data);
    final requestJson = _extractRequestMap(raw);

    return SuperAdminIosInternalTestingRequestModel.fromJson(requestJson);
  }

  Future<SuperAdminIosInternalTestingRequestModel> syncRequest(
    int requestId,
  ) async {
    final response = await _dio.post(
      '/super-admin/ios-internal-requests/$requestId/sync',
    );

    final raw = _asMap(response.data);
    final requestJson = _extractRequestMap(raw);

    return SuperAdminIosInternalTestingRequestModel.fromJson(requestJson);
  }

  Future<int> syncAll(List<int> requestIds) async {
    int updated = 0;

    for (final id in requestIds) {
      try {
        await syncRequest(id);
        updated++;
      } catch (_) {
        // keep going
      }
    }

    return updated;
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
    if (request is Map<String, dynamic>) return request;
    if (request is Map) return Map<String, dynamic>.from(request);
    return raw;
  }
}
