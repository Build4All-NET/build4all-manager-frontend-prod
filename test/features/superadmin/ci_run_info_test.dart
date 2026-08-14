import 'package:build4all_manager/features/superadmin/shared/ci_run_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// The run link is a super-admin escape hatch into CI, so the rule for when it
/// appears is the part worth pinning down: offer it while a build still needs
/// looking at, and stay quiet otherwise.
void main() {
  const runUrl = 'https://github.com/acme/app/actions/runs/991122';

  CiRunInfo info(String? status, {String? url = runUrl, int? number = 4821}) =>
      CiRunInfo(buildStatus: status, ciRunNumber: number, ciRunUrl: url);

  group('shows the link while a build still needs looking at', () {
    test('failed build', () {
      expect(info('FAILED').showLink, isTrue);
      expect(info('FAILED').isFailed, isTrue);
    });

    test('running build', () {
      expect(info('RUNNING').showLink, isTrue);
      expect(info('RUNNING').isRunning, isTrue);
    });

    test('queued build counts as in flight', () {
      expect(info('QUEUED').showLink, isTrue);
      expect(info('QUEUED').isRunning, isTrue);
    });

    test('status casing from the backend does not matter', () {
      expect(info('failed').showLink, isTrue);
      expect(info('Running').showLink, isTrue);
    });
  });

  group('stays quiet otherwise', () {
    test('successful build has no logs worth chasing', () {
      expect(info('SUCCESS').showLink, isFalse);
      expect(info('SUCCESS').isFailed, isFalse);
      expect(info('SUCCESS').isRunning, isFalse);
    });

    test('app that never built', () {
      expect(info(null, url: null, number: null).showLink, isFalse);
      expect(CiRunInfo.none.showLink, isFalse);
    });

    test('unknown status is not treated as actionable', () {
      expect(info('CANCELLED').showLink, isFalse);
      expect(info('').showLink, isFalse);
    });
  });

  group('needs a URL to link to', () {
    test('failed build with no run URL', () {
      expect(info('FAILED', url: null).showLink, isFalse);
    });

    test('blank and whitespace-only URLs do not count', () {
      expect(info('FAILED', url: '').showLink, isFalse);
      expect(info('FAILED', url: '   ').showLink, isFalse);
    });

    test('a run number alone is not enough', () {
      expect(info('RUNNING', url: null, number: 4821).showLink, isFalse);
    });
  });

  test('a URL without a run number still links — the label falls back', () {
    final withoutNumber = info('FAILED', number: null);
    expect(withoutNumber.showLink, isTrue);
    expect(withoutNumber.ciRunNumber, isNull);
  });
}
