import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Renders legal copy with the URLs and e-mail addresses it contains turned
/// into tappable links that open outside the app.
///
/// Recognizers are owned by the state so they are disposed with the widget.
class LegalRichText extends StatefulWidget {
  /// Optional bold lead-in printed before [text] (e.g. `Registration.`).
  final String? lead;

  /// Optional clause reference printed before the lead (e.g. `3.1`).
  final String? ref;

  final String text;
  final TextStyle? style;
  final TextStyle? leadStyle;
  final TextAlign textAlign;

  const LegalRichText({
    super.key,
    required this.text,
    this.lead,
    this.ref,
    this.style,
    this.leadStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  State<LegalRichText> createState() => _LegalRichTextState();
}

class _LegalRichTextState extends State<LegalRichText> {
  /// Matches bare URLs and e-mail addresses inside a paragraph. Trailing
  /// sentence punctuation is deliberately excluded from the match.
  static final _linkPattern = RegExp(
    r'(https?://[^\s<>()\[\]"]+[^\s<>()\[\]".,;:])'
    r'|([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,})',
  );

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

  Future<void> _open(String raw) async {
    final uri = raw.contains('@') && !raw.startsWith('http')
        ? Uri(scheme: 'mailto', path: raw)
        : Uri.parse(raw);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<InlineSpan> _linkSpans(String text, TextStyle? style, Color linkColor) {
    final spans = <InlineSpan>[];
    var index = 0;

    for (final match in _linkPattern.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }

      final raw = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _open(raw);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: raw,
          style: style?.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
            fontWeight: FontWeight.w600,
          ),
          recognizer: recognizer,
        ),
      );

      index = match.end;
    }

    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;

    // Recognizers are rebuilt on every build, so retire the previous batch.
    _disposeRecognizers();

    final leadStyle = widget.leadStyle ??
        baseStyle?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (widget.ref != null && widget.ref!.isNotEmpty)
            TextSpan(
              text: '${widget.ref}  ',
              style: baseStyle?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          if (widget.lead != null && widget.lead!.isNotEmpty)
            TextSpan(text: '${widget.lead} ', style: leadStyle),
          ..._linkSpans(widget.text, baseStyle, cs.primary),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
