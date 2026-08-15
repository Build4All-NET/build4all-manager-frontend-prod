import 'package:dio/dio.dart';

/// Super-admin platform endpoints: the dashboard counters and the two
/// listings the dashboard drills down into.
class SuperAdminDashboardApi {
  final Dio dio;

  SuperAdminDashboardApi(this.dio);

  /// GET /api/superadmin/dashboard/overview
  Future<Response> overview() => dio.get('/superadmin/dashboard/overview');

  /// GET /api/superadmin/dashboard/owners
  Future<Response> owners() => dio.get('/superadmin/dashboard/owners');

  /// GET /api/superadmin/build-jobs — newest first, optionally one status.
  Future<Response> buildJobs({String? status, int limit = 100}) => dio.get(
        '/superadmin/build-jobs',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'limit': limit,
        },
      );
}
