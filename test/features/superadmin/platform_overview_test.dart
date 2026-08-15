import 'package:build4all_manager/features/superadmin/dashboard/data/models/platform_overview_dto.dart';
import 'package:build4all_manager/features/superadmin/dashboard/domain/entities/dashboard_overview.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/builds_screen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/owners_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dashboard reads these counters straight off the wire, so what matters
/// is that a partial or older payload degrades into zeros instead of throwing
/// — the dashboard is the first screen a super-admin sees, and it must render.
void main() {
  group('platform overview payload', () {
    test('reads every group of counters', () {
      final dto = PlatformOverviewDto.fromJson({
        'projects': {'total': 2, 'active': 2, 'inactive': 0},
        'apps': {
          'total': 14,
          'byStatus': {'ACTIVE': 11, 'SUSPENDED': 2, 'EXPIRED': 1},
          'byPlan': {'FREE': 8, 'PRO': 6},
        },
        'owners': {'total': 23, 'withApps': 9},
        'builds': {
          'total': 148,
          'byStatus': {'SUCCESS': 131, 'FAILED': 14, 'QUEUED': 1, 'RUNNING': 2},
          'byPlatform': {'ANDROID': 120, 'IOS': 28},
          'lastSevenDays': 17,
          'inFlight': 3,
        },
        'publishing': {
          'total': 21,
          'byStatus': {'PUBLISHED': 12, 'REJECTED': 2},
          'published': 12,
          'awaitingReview': 4,
        },
        'licensing': {
          'pendingUpgradeRequests': 3,
          'expiringWithin30Days': 5,
          'expired': 2,
        },
      });

      expect(dto.apps.total, 14);
      expect(dto.apps.active, 11);
      expect(dto.apps.byPlan['PRO'], 6);
      expect(dto.owners.withApps, 9);
      expect(dto.builds.failed, 14);
      expect(dto.builds.inFlight, 3);
      expect(dto.builds.byPlatform['IOS'], 28);
      expect(dto.publishing.published, 12);
      expect(dto.publishing.rejected, 2);
      expect(dto.licensing.expiringWithin30Days, 5);
    });

    test('a payload missing whole groups reads as zeros', () {
      final dto = PlatformOverviewDto.fromJson({'projects': {'total': 1}});

      expect(dto.apps.total, 0);
      expect(dto.apps.byStatus, isEmpty);
      expect(dto.builds.inFlight, 0);
      expect(dto.owners.total, 0);
      expect(dto.licensing.expired, 0);
    });

    test('counts arriving as strings are still read as numbers', () {
      final dto = PlatformOverviewDto.fromJson({
        'apps': {
          'total': '14',
          'byStatus': {'ACTIVE': '11'},
        },
      });

      expect(dto.apps.total, 14);
      expect(dto.apps.active, 11);
    });

    test('a status breakdown of the wrong shape is ignored, not fatal', () {
      final dto = PlatformOverviewDto.fromJson({
        'builds': {'total': 5, 'byStatus': 'not-a-map'},
      });

      expect(dto.builds.total, 5);
      expect(dto.builds.byStatus, isEmpty);
    });
  });

  group('dashboard overview', () {
    test('platform sections stay hidden when the endpoint did not answer', () {
      const overview = DashboardOverview(
        totalProjects: 2,
        activeProjects: 2,
        inactiveProjects: 0,
      );

      expect(overview.hasPlatformStats, isFalse);
    });

    test('a platform with nothing on it still shows its sections', () {
      // All zeros is an answer: the sections belong on screen, reading zero.
      const overview = DashboardOverview(
        totalProjects: 2,
        activeProjects: 2,
        inactiveProjects: 0,
        platformStatsAvailable: true,
      );

      expect(overview.hasPlatformStats, isTrue);
      expect(overview.apps.total, 0);
    });
  });

  group('drill-down rows', () {
    test('a build row keeps the CI link and the owner behind it', () {
      final row = BuildJobRow.fromJson({
        'id': 501,
        'aupId': 42,
        'appName': 'Beirut Coffee',
        'slug': 'opl42',
        'ownerName': 'Kassem Fawaz',
        'ownerEmail': 'k@build4all.net',
        'platform': 'ANDROID',
        'status': 'FAILED',
        'ciRunNumber': 4821,
        'ciRunUrl': 'https://github.com/acme/app/actions/runs/4821',
        'versionName': '1.4.2',
        'createdAt': '2026-08-15T09:40:00',
        'error': 'Gradle build failed',
      });

      expect(row.status, 'FAILED');
      expect(row.ciRunNumber, 4821);
      expect(row.ownerName, 'Kassem Fawaz');
      expect(row.createdAt, DateTime.parse('2026-08-15T09:40:00'));
    });

    test('a build with no CI run recorded leaves the link null', () {
      final row = BuildJobRow.fromJson({
        'id': 1,
        'aupId': 2,
        'status': 'QUEUED',
        'ciRunUrl': '',
        'error': '   ',
      });

      expect(row.ciRunUrl, isNull);
      expect(row.ciRunNumber, isNull);
      expect(row.error, isNull);
    });

    test('an owner with a placeholder phone is treated as having none', () {
      final row = OwnerRow.fromJson({
        'adminId': 9,
        'name': '',
        'username': 'owner_9',
        'email': 'owner9@example.com',
        'phoneNumber': '',
        'appsCount': 0,
      });

      expect(row.phoneNumber, isNull);
      expect(row.appsCount, 0);
      expect(row.username, 'owner_9');
    });
  });
}
