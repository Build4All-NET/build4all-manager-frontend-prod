import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/upgrade_requests_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// The super-admin decides on upgrade requests from this row alone, so the
/// identity it carries — shop, owner, e-mail — is the part worth pinning down,
/// including what it falls back to when the backend has nothing to give.
void main() {
  Map<String, dynamic> json({
    String? appName,
    String? slug,
    String? ownerName,
    String? ownerEmail,
    String? businessName,
    Object? businessCount,
  }) =>
      {
        'id': 12,
        'aupId': 42,
        'appName': appName,
        'slug': slug,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'businessName': businessName,
        'businessCount': businessCount,
        'requestedPlanCode': 'PRO',
        'billingCycle': 'MONTHLY',
        'usersAllowedOverride': null,
        'requestedAt': '2026-08-15T10:00:00',
      };

  group('identity of a request', () {
    test('carries the shop, the owner, and how to reach them', () {
      final row = UpgradeRequestRow.fromJson(json(
        appName: 'Coffee App',
        slug: 'opl42',
        ownerName: 'Kassem Fawaz',
        ownerEmail: 'k@build4all.net',
        businessName: 'Beirut Coffee House',
        businessCount: 1,
      ));

      expect(row.businessName, 'Beirut Coffee House');
      expect(row.ownerName, 'Kassem Fawaz');
      expect(row.ownerEmail, 'k@build4all.net');
      expect(row.businessCount, 1);
    });

    test('a row from a backend that sends none of it stays empty, not null', () {
      final row = UpgradeRequestRow.fromJson(json(appName: 'App', slug: 'opl42'));

      expect(row.businessName, isEmpty);
      expect(row.ownerName, isEmpty);
      expect(row.ownerEmail, isEmpty);
      expect(row.businessCount, 0);
    });

    test('a shop count arriving as a string is still read as a number', () {
      final row = UpgradeRequestRow.fromJson(json(businessCount: '3'));

      expect(row.businessCount, 3);
    });
  });
}
