import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/project_summary.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import '../models/platform_overview_dto.dart';
import '../models/project_dto.dart';
import '../services/project_api.dart';
import '../services/licensing_api.dart';
import '../services/superadmin_dashboard_api.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ProjectApi projects;
  final LicensingApi licensing;
  final SuperAdminDashboardApi platform;

  DashboardRepositoryImpl(this.projects, this.licensing, this.platform);

  @override
  Future<(DashboardOverview, List<ProjectSummary>)> load() async {
    // All three requests are independent, so fire them together — running
    // them in sequence multiplied how long the dashboard takes to show
    // anything.
    final projectsFuture = projects.list();

    // The platform counters are a newer endpoint. If the backend does not
    // serve them yet, the dashboard falls back to the project figures rather
    // than failing outright.
    final platformFuture = platform.overview().then<PlatformOverviewDto?>((r) {
      final data = r.data;
      return data is Map
          ? PlatformOverviewDto.fromJson(Map<String, dynamic>.from(data))
          : null;
    }).catchError((Object _) => null);

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

    final stats = await platformFuture;
    final pendingCount = await pendingFuture;

    return (
      DashboardOverview(
        totalProjects: total,
        activeProjects: active,
        inactiveProjects: inactive,
        // The overview carries the pending count too; keep the dedicated
        // request as the fallback for an older backend.
        pendingUpgradeRequests:
            stats?.licensing.pendingUpgradeRequests ?? pendingCount,
        platformStatsAvailable: stats != null,
        apps: stats?.apps ?? const AppsStats(),
        owners: stats?.owners ?? const OwnersStats(),
        builds: stats?.builds ?? const BuildsStats(),
        publishing: stats?.publishing ?? const PublishingStats(),
        licensing: stats?.licensing ?? const LicensingStats(),
      ),
      recent
    );
  }
}
