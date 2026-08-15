/// Immutable model of the Terms & Conditions document shipped as a static
/// JSON asset (`assets/legal/terms_<lang>.json`).
///
/// The document is intentionally offline-only: it is versioned with the app
/// build, so no backend call is involved in reading or accepting the terms.
library;

/// A single renderable piece of a section.
sealed class TermsBlock {
  const TermsBlock();

  static TermsBlock fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'p';

    return switch (type) {
      'list' => TermsListBlock(
          style: json['style'] as String? ?? 'lettered',
          items: [
            for (final item in (json['items'] as List? ?? const []))
              TermsListItem(
                marker: (item as Map)['marker'] as String? ?? '',
                text: item['text'] as String? ?? '',
              ),
          ],
        ),
      'table' => TermsTableBlock(
          columns: [
            for (final column in (json['columns'] as List? ?? const []))
              column as String,
          ],
          rows: [
            for (final row in (json['rows'] as List? ?? const []))
              [for (final cell in (row as List)) cell as String],
          ],
        ),
      'contact' => TermsContactBlock(
          lines: [
            for (final line in (json['lines'] as List? ?? const []))
              line as String,
          ],
        ),
      _ => TermsParagraphBlock(
          ref: json['ref'] as String?,
          lead: json['lead'] as String?,
          text: json['text'] as String? ?? '',
          emphasised: type == 'caution',
        ),
    };
  }
}

/// A paragraph, optionally numbered (`3.1`) and opening with a bold lead-in.
///
/// [emphasised] marks the legally loud clauses (disclaimers, liability caps)
/// that are set in capitals in the source document.
class TermsParagraphBlock extends TermsBlock {
  final String? ref;
  final String? lead;
  final String text;
  final bool emphasised;

  const TermsParagraphBlock({
    required this.text,
    this.ref,
    this.lead,
    this.emphasised = false,
  });
}

class TermsListItem {
  final String marker;
  final String text;

  const TermsListItem({required this.marker, required this.text});
}

class TermsListBlock extends TermsBlock {
  /// `lettered` (a. b. c.) or `numbered` (1. 2. 3.).
  final String style;
  final List<TermsListItem> items;

  const TermsListBlock({required this.style, required this.items});
}

/// Two-column definitions table (Term / Meaning).
class TermsTableBlock extends TermsBlock {
  final List<String> columns;
  final List<List<String>> rows;

  const TermsTableBlock({required this.columns, required this.rows});
}

class TermsContactBlock extends TermsBlock {
  final List<String> lines;

  const TermsContactBlock({required this.lines});
}

class TermsSection {
  final String number;
  final String title;
  final List<TermsBlock> blocks;

  const TermsSection({
    required this.number,
    required this.title,
    required this.blocks,
  });

  factory TermsSection.fromJson(Map<String, dynamic> json) => TermsSection(
        number: json['number'] as String? ?? '',
        title: json['title'] as String? ?? '',
        blocks: [
          for (final block in (json['blocks'] as List? ?? const []))
            TermsBlock.fromJson(Map<String, dynamic>.from(block as Map)),
        ],
      );
}

class TermsAcknowledgement {
  final String title;
  final String text;
  final String checkbox;

  const TermsAcknowledgement({
    required this.title,
    required this.text,
    required this.checkbox,
  });

  factory TermsAcknowledgement.fromJson(Map<String, dynamic> json) =>
      TermsAcknowledgement(
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        checkbox: json['checkbox'] as String? ?? '',
      );
}

class TermsDocument {
  /// Language of this copy of the document (`en`, `fr`, `ar`).
  final String language;
  final String title;
  final String version;
  final String effectiveDate;
  final String lastUpdated;
  final List<TermsSection> sections;
  final TermsAcknowledgement acknowledgement;

  const TermsDocument({
    required this.language,
    required this.title,
    required this.version,
    required this.effectiveDate,
    required this.lastUpdated,
    required this.sections,
    required this.acknowledgement,
  });

  factory TermsDocument.fromJson(Map<String, dynamic> json) => TermsDocument(
        language: json['language'] as String? ?? 'en',
        title: json['title'] as String? ?? '',
        version: json['version'] as String? ?? '',
        effectiveDate: json['effectiveDate'] as String? ?? '',
        lastUpdated: json['lastUpdated'] as String? ?? '',
        sections: [
          for (final section in (json['sections'] as List? ?? const []))
            TermsSection.fromJson(Map<String, dynamic>.from(section as Map)),
        ],
        acknowledgement: TermsAcknowledgement.fromJson(
          Map<String, dynamic>.from(
            (json['acknowledgement'] as Map?) ?? const {},
          ),
        ),
      );
}
