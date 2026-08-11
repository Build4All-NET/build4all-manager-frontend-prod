import 'package:flutter/material.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../../woocommerce/data/models/woo_config_models.dart';

/// Everything the wizard needs to know about the store choice.
///
/// [connectionOk] is tracked separately from the credentials on purpose: it is
/// reset the moment any field changes, so a passing test can never be carried
/// over onto edited credentials.
class CommerceSourceDraft {
  final CommerceSource source;
  final String storeUrl;
  final String consumerKey;
  final String consumerSecret;
  final bool connectionOk;

  const CommerceSourceDraft({
    this.source = CommerceSource.build4all,
    this.storeUrl = '',
    this.consumerKey = '',
    this.consumerSecret = '',
    this.connectionOk = false,
  });

  bool get isWoo => source.isWoo;

  bool get hasAllFields =>
      storeUrl.trim().isNotEmpty &&
      consumerKey.trim().isNotEmpty &&
      consumerSecret.trim().isNotEmpty;

  /// Build4All apps need nothing; WooCommerce apps must have credentials that
  /// have actually been tested.
  bool get isReadyToSubmit => !isWoo || (hasAllFields && connectionOk);

  CommerceSourceDraft copyWith({
    CommerceSource? source,
    String? storeUrl,
    String? consumerKey,
    String? consumerSecret,
    bool? connectionOk,
  }) {
    return CommerceSourceDraft(
      source: source ?? this.source,
      storeUrl: storeUrl ?? this.storeUrl,
      consumerKey: consumerKey ?? this.consumerKey,
      consumerSecret: consumerSecret ?? this.consumerSecret,
      connectionOk: connectionOk ?? this.connectionOk,
    );
  }
}

/// The "Commerce" panel of the create-app wizard.
///
/// Kept as a plain callback widget, like the palette section, so the wizard
/// keeps owning the state and the submit rules.
class CommerceSourceSection extends StatelessWidget {
  final CommerceSourceDraft draft;
  final ValueChanged<CommerceSourceDraft> onChanged;

  final TextEditingController storeUrlCtrl;
  final TextEditingController consumerKeyCtrl;
  final TextEditingController consumerSecretCtrl;

  final bool testing;
  final String? testError;
  final VoidCallback onTest;

  const CommerceSourceSection({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.storeUrlCtrl,
    required this.consumerKeyCtrl,
    required this.consumerSecretCtrl,
    required this.testing,
    required this.testError,
    required this.onTest,
  });

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.owner_request_commerce_title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          l.owner_request_commerce_subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        _SourceCard(
          selected: !draft.isWoo,
          icon: Icons.storefront_outlined,
          title: l.owner_request_commerce_build4all,
          subtitle: l.owner_request_commerce_build4all_hint,
          onTap: () => onChanged(
              draft.copyWith(source: CommerceSource.build4all)),
        ),
        const SizedBox(height: 8),
        _SourceCard(
          selected: draft.isWoo,
          icon: Icons.shopping_bag_outlined,
          title: l.owner_request_commerce_woo,
          subtitle: l.owner_request_commerce_woo_hint,
          onTap: () => onChanged(
              draft.copyWith(source: CommerceSource.woocommerce)),
        ),

        if (draft.isWoo) ...[
          const SizedBox(height: 16),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 16),
          ..._wooFields(context, l, cs),
        ],
      ],
    );
  }

  List<Widget> _wooFields(
      BuildContext context, AppLocalizations l, ColorScheme cs) {
    // Any edit invalidates a previous successful test — otherwise an owner
    // could test one store, paste different keys, and submit against an
    // unverified one.
    void invalidate(CommerceSourceDraft next) =>
        onChanged(next.copyWith(connectionOk: false));

    return [
      _field(
        context: context,
        controller: storeUrlCtrl,
        label: l.owner_request_woo_store_url,
        hint: l.owner_request_woo_store_url_hint,
        icon: Icons.link,
        onChanged: (v) => invalidate(draft.copyWith(storeUrl: v)),
      ),
      const SizedBox(height: 10),
      _field(
        context: context,
        controller: consumerKeyCtrl,
        label: l.owner_request_woo_consumer_key,
        hint: 'ck_...',
        icon: Icons.vpn_key_outlined,
        onChanged: (v) => invalidate(draft.copyWith(consumerKey: v)),
      ),
      const SizedBox(height: 10),
      _field(
        context: context,
        controller: consumerSecretCtrl,
        label: l.owner_request_woo_consumer_secret,
        hint: 'cs_...',
        icon: Icons.lock_outline,
        obscure: true,
        onChanged: (v) => invalidate(draft.copyWith(consumerSecret: v)),
      ),
      const SizedBox(height: 8),
      Text(
        l.owner_request_woo_keys_help,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 14),

      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: (testing || !draft.hasAllFields) ? null : onTest,
          icon: testing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(testing
              ? l.owner_request_woo_testing
              : l.owner_request_woo_test),
        ),
      ),

      if (draft.connectionOk) ...[
        const SizedBox(height: 10),
        _Banner(
          icon: Icons.check_circle_outline,
          color: _green,
          text: l.owner_request_woo_test_ok,
        ),
      ] else if (testError != null) ...[
        const SizedBox(height: 10),
        _Banner(
          icon: Icons.error_outline,
          color: cs.error,
          text: l.owner_request_woo_test_failed(testError!),
        ),
      ],

      const SizedBox(height: 12),
      _Banner(
        icon: Icons.info_outline,
        color: cs.onSurfaceVariant,
        text: l.owner_request_woo_readonly_note,
      ),
    ];
  }

  Widget _field({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _green.withOpacity(.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _green : cs.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? _green : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: selected ? _green : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? _green : cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }
}
