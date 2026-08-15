/// Platform-wide counters behind the super-admin dashboard.
///
/// The project figures are the originals; everything else comes from
/// `/superadmin/dashboard/overview`. A backend that does not serve that
/// endpoint yet simply leaves the extra groups empty — the dashboard keeps
/// working on the project numbers alone.
class DashboardOverview {
  final int totalProjects;
  final int activeProjects;
  final int inactiveProjects;

  final int pendingUpgradeRequests;

  final AppsStats apps;
  final OwnersStats owners;
  final BuildsStats builds;
  final PublishingStats publishing;
  final LicensingStats licensing;

  const DashboardOverview({
    required this.totalProjects,
    required this.activeProjects,
    required this.inactiveProjects,
    this.pendingUpgradeRequests = 0,
    this.apps = const AppsStats(),
    this.owners = const OwnersStats(),
    this.builds = const BuildsStats(),
    this.publishing = const PublishingStats(),
    this.licensing = const LicensingStats(),
  });

  /// Whether the platform-wide groups were actually served. Used to hide the
  /// extra sections rather than render a wall of zeros.
  bool get hasPlatformStats =>
      apps.total > 0 ||
      owners.total > 0 ||
      builds.total > 0 ||
      publishing.total > 0;
}

class AppsStats {
  final int total;

  /// Keyed by app status (`ACTIVE`, `SUSPENDED`, `EXPIRED`, ...).
  final Map<String, int> byStatus;

  /// Keyed by plan code (`FREE`, `PRO`, ...) across live subscriptions.
  final Map<String, int> byPlan;

  const AppsStats({
    this.total = 0,
    this.byStatus = const {},
    this.byPlan = const {},
  });

  int get active => byStatus['ACTIVE'] ?? 0;
  int get suspended => byStatus['SUSPENDED'] ?? 0;
}

class OwnersStats {
  final int total;
  final int withApps;

  const OwnersStats({this.total = 0, this.withApps = 0});
}

class BuildsStats {
  final int total;
  final int inFlight;
  final int lastSevenDays;
  final Map<String, int> byStatus;
  final Map<String, int> byPlatform;

  const BuildsStats({
    this.total = 0,
    this.inFlight = 0,
    this.lastSevenDays = 0,
    this.byStatus = const {},
    this.byPlatform = const {},
  });

  int get succeeded => byStatus['SUCCESS'] ?? 0;
  int get failed => byStatus['FAILED'] ?? 0;
}

class PublishingStats {
  final int total;
  final int published;
  final int awaitingReview;
  final Map<String, int> byStatus;

  const PublishingStats({
    this.total = 0,
    this.published = 0,
    this.awaitingReview = 0,
    this.byStatus = const {},
  });

  int get rejected => byStatus['REJECTED'] ?? 0;
}

class LicensingStats {
  final int pendingUpgradeRequests;
  final int expiringWithin30Days;
  final int expired;

  const LicensingStats({
    this.pendingUpgradeRequests = 0,
    this.expiringWithin30Days = 0,
    this.expired = 0,
  });
}
