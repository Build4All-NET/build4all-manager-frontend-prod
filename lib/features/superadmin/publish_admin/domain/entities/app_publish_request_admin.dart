import '../../../shared/ci_run_info.dart';
import 'publisher_profile.dart';

class AppPublishRequestAdmin {
  final int id;

  final int? aupId;
  final String? appName;

  final String platform; // ANDROID / IOS
  final String store; // PLAY_STORE / APP_STORE
  final String status; // DRAFT / SUBMITTED / APPROVED ...

  final DateTime? requestedAt;
  final DateTime? reviewedAt;

  final String? packageNameSnapshot;
  final String? bundleIdSnapshot;

  final String shortDescription;
  final String fullDescription;
  final String category;

  final String pricing; // FREE / PAID
  final bool contentRatingConfirmed;

  final String? appIconUrl;
  final List<String> screenshotsUrls;

  final String? adminNotes;

  final PublisherProfile? publisherProfile;
  final int? androidVersionCode;
  final String? androidVersionName;
  final int? iosBuildNumber;
  final String? iosVersionName;

  final String? apkUrl;
  final String? bundleUrl; // AAB
  final String? ipaUrl;
  final String? logoUrl;

  /// Latest CI build job for this app + platform.
  ///
  /// SUPER_ADMIN only — the backend never puts these on the owner-facing DTO.
  final String? buildStatus; // QUEUED / RUNNING / SUCCESS / FAILED
  final int? ciRunNumber;
  final String? ciRunUrl;


  const AppPublishRequestAdmin({
    required this.id,
    required this.aupId,
    required this.appName,
    required this.platform,
    required this.store,
    required this.status,
    required this.requestedAt,
    required this.reviewedAt,
    required this.packageNameSnapshot,
    required this.bundleIdSnapshot,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.pricing,
    required this.contentRatingConfirmed,
    required this.appIconUrl,
    required this.screenshotsUrls,
    required this.adminNotes,
    required this.publisherProfile,
    this.androidVersionCode,
    this.androidVersionName,
    this.iosBuildNumber,
    this.iosVersionName,
    this.apkUrl,
    this.bundleUrl,
    this.ipaUrl,
    this.logoUrl,
    this.buildStatus,
    this.ciRunNumber,
    this.ciRunUrl,
  });

  bool get isSubmitted => status.toUpperCase() == 'SUBMITTED';

  CiRunInfo get ciRunInfo => CiRunInfo(
        buildStatus: buildStatus,
        ciRunNumber: ciRunNumber,
        ciRunUrl: ciRunUrl,
      );

  bool get showCiRunLink => ciRunInfo.showLink;
}
