import '../../domain/entities/dashboard_overview.dart';

/// Parses `/superadmin/dashboard/overview`.
///
/// Every field is read defensively: a backend that predates one of these
/// groups just yields zeros rather than breaking the dashboard.
class PlatformOverviewDto {
  final AppsStats apps;
  final OwnersStats owners;
  final BuildsStats builds;
  final PublishingStats publishing;
  final LicensingStats licensing;
  final int projectsTotal;
  final int projectsActive;
  final int projectsInactive;

  const PlatformOverviewDto({
    required this.apps,
    required this.owners,
    required this.builds,
    required this.publishing,
    required this.licensing,
    required this.projectsTotal,
    required this.projectsActive,
    required this.projectsInactive,
  });

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static Map<String, dynamic> _group(dynamic json, String key) {
    final value = (json is Map) ? json[key] : null;
    return value is Map ? Map<String, dynamic>.from(value) : const {};
  }

  static Map<String, int> _counts(Map<String, dynamic> group, String key) {
    final value = group[key];
    if (value is! Map) return const {};

    return {
      for (final entry in value.entries) entry.key.toString(): _int(entry.value),
    };
  }

  factory PlatformOverviewDto.fromJson(Map<String, dynamic> json) {
    final projects = _group(json, 'projects');
    final apps = _group(json, 'apps');
    final owners = _group(json, 'owners');
    final builds = _group(json, 'builds');
    final publishing = _group(json, 'publishing');
    final licensing = _group(json, 'licensing');

    return PlatformOverviewDto(
      projectsTotal: _int(projects['total']),
      projectsActive: _int(projects['active']),
      projectsInactive: _int(projects['inactive']),
      apps: AppsStats(
        total: _int(apps['total']),
        byStatus: _counts(apps, 'byStatus'),
        byPlan: _counts(apps, 'byPlan'),
      ),
      owners: OwnersStats(
        total: _int(owners['total']),
        withApps: _int(owners['withApps']),
      ),
      builds: BuildsStats(
        total: _int(builds['total']),
        inFlight: _int(builds['inFlight']),
        lastSevenDays: _int(builds['lastSevenDays']),
        byStatus: _counts(builds, 'byStatus'),
        byPlatform: _counts(builds, 'byPlatform'),
      ),
      publishing: PublishingStats(
        total: _int(publishing['total']),
        published: _int(publishing['published']),
        awaitingReview: _int(publishing['awaitingReview']),
        byStatus: _counts(publishing, 'byStatus'),
      ),
      licensing: LicensingStats(
        pendingUpgradeRequests: _int(licensing['pendingUpgradeRequests']),
        expiringWithin30Days: _int(licensing['expiringWithin30Days']),
        expired: _int(licensing['expired']),
      ),
    );
  }
}
