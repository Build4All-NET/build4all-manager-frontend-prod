/// The GitHub Actions run behind an app's latest CI build.
///
/// SUPER_ADMIN data: the backend keeps the run number and URL off every
/// owner-facing DTO, so an owner's app has no field to render.
///
/// Plain Dart with no Flutter dependency, so domain entities and data models can
/// both expose one and the rule for when a run is worth surfacing lives in a
/// single place rather than being restated per screen.
class CiRunInfo {
  /// QUEUED / RUNNING / SUCCESS / FAILED, or null when the app never built.
  final String? buildStatus;
  final int? ciRunNumber;
  final String? ciRunUrl;

  const CiRunInfo({
    this.buildStatus,
    this.ciRunNumber,
    this.ciRunUrl,
  });

  static const CiRunInfo none = CiRunInfo();

  String get _status => (buildStatus ?? '').toUpperCase();

  bool get isRunning => _status == 'RUNNING' || _status == 'QUEUED';

  bool get isFailed => _status == 'FAILED';

  /// The run link is only offered while a build still needs looking at — a failed
  /// or in-flight one. A finished, successful build has no logs worth chasing.
  bool get showLink =>
      (isFailed || isRunning) && (ciRunUrl ?? '').trim().isNotEmpty;
}
