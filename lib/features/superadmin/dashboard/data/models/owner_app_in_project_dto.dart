import '../../../shared/ci_run_info.dart';

class OwnerAppInProjectDto {
  final int id; // AdminUserProject id
  final String slug;
  final String appName;
  final String status;
  final String? apkUrl;
  final String? ipaUrl;
  final String? bundleUrl;

  // Latest CI build job (SUPER_ADMIN only — absent from every owner DTO).
  final String? buildStatus;
  final int? ciRunNumber;
  final String? ciRunUrl;

  OwnerAppInProjectDto({
    required this.id,
    required this.slug,
    required this.appName,
    required this.status,
    this.apkUrl,
    this.ipaUrl,
    this.bundleUrl,
    this.buildStatus,
    this.ciRunNumber,
    this.ciRunUrl,
  });

  CiRunInfo get ciRunInfo => CiRunInfo(
        buildStatus: buildStatus,
        ciRunNumber: ciRunNumber,
        ciRunUrl: ciRunUrl,
      );

  factory OwnerAppInProjectDto.fromJson(Map<String, dynamic> json) {
    return OwnerAppInProjectDto(
      id: (json['id'] as num).toInt(),
      slug: (json['slug'] ?? '').toString(),
      appName: (json['appName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      apkUrl: json['apkUrl']?.toString(),
      ipaUrl: json['ipaUrl']?.toString(),
      bundleUrl: json['bundleUrl']?.toString(),
      buildStatus: json['buildStatus']?.toString(),
      ciRunNumber: json['ciRunNumber'] == null
          ? null
          : int.tryParse(json['ciRunNumber'].toString()),
      ciRunUrl: json['ciRunUrl']?.toString(),
    );
  }
}
