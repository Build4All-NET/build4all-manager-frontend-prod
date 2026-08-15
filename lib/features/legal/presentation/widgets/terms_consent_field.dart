import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// Consent checkbox shown above the "Create account" button.
///
/// The box cannot be ticked directly: tapping it (or the terms link) opens the
/// full terms, and only accepting there ticks it — so the account is never
/// created before the terms have actually been opened and agreed to.
class TermsConsentField extends StatefulWidget {
  final bool accepted;

  /// Called when the user unticks an already accepted box.
  final VoidCallback onRevoke;

  /// Called when the user asks to read the terms.
  final VoidCallback onOpenTerms;

  /// Highlights the field after a submit attempt without consent.
  final bool showError;

  const TermsConsentField({
    super.key,
    required this.accepted,
    required this.onRevoke,
    required this.onOpenTerms,
    this.showError = false,
  });

  @override
  State<TermsConsentField> createState() => _TermsConsentFieldState();
}

class _TermsConsentFieldState extends State<TermsConsentField> {
  static final _privacyPolicyUrl =
      Uri.parse('https://build4all.net/privacy-policy/');

  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _recognizer(VoidCallback onTap) {
    final recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  void _toggle() {
    if (widget.accepted) {
      widget.onRevoke();
      return;
    }
    widget.onOpenTerms();
  }

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(_privacyPolicyUrl, mode: LaunchMode.externalApplication);
  }

  /// Splits the localized consent sentence on its `{terms}` / `{privacy}`
  /// placeholders and turns each one into a tappable link.
  List<InlineSpan> _consentSpans(AppLocalizations l10n, TextStyle? linkStyle) {
    final template = l10n.terms_consent_text;
    final replacements = {
      '{terms}': (l10n.terms_consent_terms_link, widget.onOpenTerms),
      '{privacy}': (l10n.terms_consent_privacy_link, _openPrivacyPolicy),
    };

    final pattern = RegExp(r'\{terms\}|\{privacy\}');
    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in pattern.allMatches(template)) {
      if (match.start > index) {
        spans.add(TextSpan(text: template.substring(index, match.start)));
      }

      final (label, onTap) = replacements[match.group(0)]!;
      spans.add(
        TextSpan(
          text: label,
          style: linkStyle,
          recognizer: _recognizer(onTap),
        ),
      );

      index = match.end;
    }

    if (index < template.length) {
      spans.add(TextSpan(text: template.substring(index)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Recognizers are rebuilt with the spans below.
    _disposeRecognizers();

    final borderColor = widget.showError && !widget.accepted
        ? cs.error
        : widget.accepted
            ? cs.primary.withOpacity(.55)
            : cs.outlineVariant.withOpacity(.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.accepted
                ? cs.primary.withOpacity(.06)
                : cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: widget.accepted,
                      onChanged: (_) => _toggle(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              style: tt.bodySmall?.copyWith(height: 1.5),
                              children: _consentSpans(
                                l10n,
                                tt.bodySmall?.copyWith(
                                  height: 1.5,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  decorationColor: cs.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                widget.accepted
                                    ? Icons.verified_rounded
                                    : Icons.menu_book_rounded,
                                size: 14,
                                color: widget.accepted
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.accepted
                                      ? l10n.terms_accepted_toast
                                      : l10n.terms_open_action,
                                  style: tt.labelSmall?.copyWith(
                                    color: widget.accepted
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: AlignmentDirectional.topStart,
          child: widget.showError && !widget.accepted
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: cs.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.terms_required_error,
                          style: tt.bodySmall?.copyWith(color: cs.error),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
