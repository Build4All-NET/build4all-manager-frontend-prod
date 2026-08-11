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

/// The "Shop" panel of the create-app wizard.
///
/// Each option states its trade-off up front — two things it gives you and one
/// it costs you — because the choice is permanent and an owner who picks wrong
/// cannot undo it from the dashboard.
class CommerceSourceSection extends StatelessWidget {
  final CommerceSourceDraft draft;
  final ValueChanged<CommerceSourceDraft> onChanged;

  final TextEditingController storeUrlCtrl;
  final TextEditingController consumerKeyCtrl;
  final TextEditingController consumerSecretCtrl;

  final bool testing;
  final String? testError;

  /// Non-null once a test has passed, e.g. "248 products, 12 categories found".
  final String? testSuccessDetail;

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
    required this.testSuccessDetail,
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
        const SizedBox(height: 14),

        _SourceCard(
          selected: !draft.isWoo,
          icon: Icons.storefront_outlined,
          title: l.owner_request_commerce_build4all,
          subtitle: l.owner_request_commerce_build4all_hint,
          badge: l.owner_request_commerce_recommended,
          pros: [
            l.owner_request_commerce_b4a_pro1,
            l.owner_request_commerce_b4a_pro2,
          ],
          cons: [l.owner_request_commerce_b4a_con1],
          onTap: () =>
              onChanged(draft.copyWith(source: CommerceSource.build4all)),
        ),
        const SizedBox(height: 10),
        _SourceCard(
          selected: draft.isWoo,
          icon: Icons.public,
          title: l.owner_request_commerce_woo,
          subtitle: l.owner_request_commerce_woo_hint,
          badge: null,
          pros: [
            l.owner_request_commerce_woo_pro1,
            l.owner_request_commerce_woo_pro2,
          ],
          cons: [l.owner_request_commerce_woo_con1],
          // Credentials live inside the card they belong to, so the form does
          // not float unattached under an unselected option.
          expanded: draft.isWoo ? _wooFields(context, l, cs) : null,
          onTap: () =>
              onChanged(draft.copyWith(source: CommerceSource.woocommerce)),
        ),
      ],
    );
  }

  Widget _wooFields(BuildContext context, AppLocalizations l, ColorScheme cs) {
    // Any edit invalidates a previous successful test — otherwise an owner
    // could test one store, paste different keys, and submit against an
    // unverified one.
    void invalidate(CommerceSourceDraft next) =>
        onChanged(next.copyWith(connectionOk: false));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          context: context,
          controller: storeUrlCtrl,
          label: l.owner_request_woo_store_url,
          hint: l.owner_request_woo_store_url_hint,
          onChanged: (v) => invalidate(draft.copyWith(storeUrl: v)),
        ),
        const SizedBox(height: 12),

        // Key and secret are issued together and pasted together; side by side
        // keeps them read as one credential rather than two settings.
        LayoutBuilder(
          builder: (context, constraints) {
            final key = _field(
              context: context,
              controller: consumerKeyCtrl,
              label: l.owner_request_woo_consumer_key,
              hint: 'ck_…',
              onChanged: (v) => invalidate(draft.copyWith(consumerKey: v)),
            );
            final secret = _field(
              context: context,
              controller: consumerSecretCtrl,
              label: l.owner_request_woo_consumer_secret,
              hint: 'cs_…',
              obscure: true,
              onChanged: (v) => invalidate(draft.copyWith(consumerSecret: v)),
            );

            if (constraints.maxWidth < 420) {
              return Column(
                children: [key, const SizedBox(height: 12), secret],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: key),
                const SizedBox(width: 12),
                Expanded(child: secret),
              ],
            );
          },
        ),

        const SizedBox(height: 8),
        Text(
          l.owner_request_woo_keys_help,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),

        // Button and verdict on one line, matching how the owner reads it:
        // press, then look immediately to the right for the answer.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: (testing || !draft.hasAllFields) ? null : onTest,
              icon: testing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering, size: 16),
              label: Text(testing
                  ? l.owner_request_woo_testing
                  : l.owner_request_woo_test),
            ),
            if (draft.connectionOk)
              _Verdict(
                icon: Icons.check_circle,
                color: _green,
                text: testSuccessDetail ?? l.owner_request_woo_test_ok,
              )
            else if (testError != null)
              _Verdict(
                icon: Icons.error_outline,
                color: cs.error,
                text: l.owner_request_woo_test_failed(testError!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
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
  final String? badge;
  final List<String> pros;
  final List<String> cons;
  final Widget? expanded;
  final VoidCallback onTap;

  const _SourceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.pros,
    required this.cons,
    required this.onTap,
    this.expanded,
  });

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _green : cs.outlineVariant,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon,
                          size: 20,
                          color: selected ? _green : cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _green,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: selected ? _green : cs.outlineVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...pros.map((t) => _Bullet(text: t, positive: true)),
                  ...cons.map((t) => _Bullet(text: t, positive: false)),
                ],
              ),
            ),
          ),
          if (expanded != null) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: expanded!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final bool positive;

  const _Bullet({required this.text, required this.positive});

  static const _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A check for what you gain, a dash for what you give up — the dash
          // is deliberately not a red cross: neither option is broken, they
          // just trade differently.
          Icon(
            positive ? Icons.check : Icons.remove,
            size: 15,
            color: positive ? _green : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: positive ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Verdict({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
