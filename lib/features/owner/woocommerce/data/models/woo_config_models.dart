/// Where an app's commerce data lives.
///
/// Mirrors the backend `CommerceSource`. Anything unrecognised — including a
/// null, which is what every app created before WooCommerce support carries —
/// reads as [build4all], so an older app can never be mistaken for a store.
enum CommerceSource {
  build4all,
  woocommerce;

  static CommerceSource parse(Object? raw) {
    final s = raw?.toString().trim().toUpperCase();
    return s == 'WOOCOMMERCE' ? CommerceSource.woocommerce : CommerceSource.build4all;
  }

  bool get isWoo => this == CommerceSource.woocommerce;
}

/// The stored WooCommerce settings for one app.
///
/// [consumerSecret] is deliberately absent: the backend never returns it.
/// [consumerSecretSet] says whether one exists, and [consumerKey] arrives
/// masked (`ck_a1b••••f7e2`) — enough to recognise, not enough to use.
class WooConfig {
  final int? ownerProjectId;
  final bool enabled;
  final String? storeUrl;
  final String? consumerKey;
  final bool consumerSecretSet;
  final String? apiVersion;
  final String? connectionStatus;
  final String? connectionMessage;
  final DateTime? lastCheckedAt;

  const WooConfig({
    required this.ownerProjectId,
    required this.enabled,
    required this.storeUrl,
    required this.consumerKey,
    required this.consumerSecretSet,
    required this.apiVersion,
    required this.connectionStatus,
    required this.connectionMessage,
    required this.lastCheckedAt,
  });

  bool get isConnected => connectionStatus == 'CONNECTED';

  factory WooConfig.fromJson(Map<String, dynamic> json) {
    DateTime? dt(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

    return WooConfig(
      ownerProjectId: json['ownerProjectId'] is int
          ? json['ownerProjectId'] as int
          : int.tryParse(json['ownerProjectId']?.toString() ?? ''),
      enabled: json['enabled'] == true,
      storeUrl: json['storeUrl']?.toString(),
      consumerKey: json['consumerKey']?.toString(),
      consumerSecretSet: json['consumerSecretSet'] == true,
      apiVersion: json['apiVersion']?.toString(),
      connectionStatus: json['connectionStatus']?.toString(),
      connectionMessage: json['connectionMessage']?.toString(),
      lastCheckedAt: dt(json['lastCheckedAt']),
    );
  }
}

/// What the settings screen needs in one shot: which source the app uses, and
/// the stored config if there is one.
class WooConfigState {
  final CommerceSource commerceSource;
  final bool configured;
  final WooConfig? config;

  const WooConfigState({
    required this.commerceSource,
    required this.configured,
    required this.config,
  });

  factory WooConfigState.fromJson(Map<String, dynamic> json) {
    final raw = json['config'];
    return WooConfigState(
      commerceSource: CommerceSource.parse(json['commerceSource']),
      configured: json['configured'] == true,
      config: raw is Map ? WooConfig.fromJson(Map<String, dynamic>.from(raw)) : null,
    );
  }
}

/// Outcome of a connection check.
///
/// A failure is a normal result to render, not an error to throw: the codes
/// map to specific causes the owner can act on — `WOO_AUTH_FAILED` means wrong
/// keys, `WOO_STORE_UNAVAILABLE` means the site is down or the URL is wrong.
class WooConnectionResult {
  final bool ok;
  final String? code;
  final String? message;

  /// What the store actually contains. -1 means the store did not report a
  /// count (some security plugins strip the X-WP-Total header), in which case
  /// the UI shows a plain "Connected" rather than inventing a number.
  final int productCount;
  final int categoryCount;

  const WooConnectionResult({
    required this.ok,
    required this.code,
    required this.message,
    this.productCount = -1,
    this.categoryCount = -1,
  });

  bool get hasCounts => ok && productCount >= 0 && categoryCount >= 0;

  factory WooConnectionResult.fromJson(Map<String, dynamic> json) {
    int count(Object? v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? -1;
    }

    return WooConnectionResult(
      ok: json['ok'] == true,
      code: (json['code'] ?? json['error'])?.toString(),
      message: (json['message'] ?? json['error'])?.toString(),
      productCount: count(json['productCount']),
      categoryCount: count(json['categoryCount']),
    );
  }
}
