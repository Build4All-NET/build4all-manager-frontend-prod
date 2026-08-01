import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/project_summary.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import '../models/project_dto.dart';
import '../services/project_api.dart';
import '../services/licensing_api.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ProjectApi projects;
  final LicensingApi licensing;

  DashboardRepositoryImpl(this.projects, this.licensing);

  @override
  Future<(DashboardOverview, List<ProjectSummary>)> load() async {
    // Both requests are independent, so fire them together — running them in
    // sequence doubled how long the dashboard takes to show anything.
    final projectsFuture = projects.list();

    // ✅ pending upgrade requests count (super admin)
    // A failure here must not take the dashboard down with it.
    final pendingFuture = licensing.pendingUpgradeRequests().then<int>((r) {
      final data = r.data;
      return data is List ? data.length : 0;
    }).catchError((Object _) => 0);

    final res = await projectsFuture;
    final list = (res.data as List).cast<Map<String, dynamic>>();
    final items = list.map((e) => ProjectDto.fromJson(e).toEntity()).toList();

    final total = items.length;
    final active = items.where((e) => e.active).length;
    final inactive = total - active;

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = items.take(8).toList();

    final pendingCount = await pendingFuture;

    return (
      DashboardOverview(
        totalProjects: total,
        activeProjects: active,
        inactiveProjects: inactive,
        pendingUpgradeRequests: pendingCount,
      ),
      recent
    );
  }
}
