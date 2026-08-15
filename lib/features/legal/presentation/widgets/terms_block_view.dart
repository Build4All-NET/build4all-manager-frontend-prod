import 'package:flutter/material.dart';

import '../../domain/entities/terms_document.dart';
import 'legal_rich_text.dart';

/// Renders one [TermsBlock]. Kept free of scrolling concerns so the same
/// widgets can be reused wherever the document is displayed.
class TermsBlockView extends StatelessWidget {
  final TermsBlock block;

  const TermsBlockView({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      TermsParagraphBlock p when p.emphasised => _CautionParagraph(block: p),
      TermsParagraphBlock p => _Paragraph(block: p),
      TermsListBlock l => _BulletList(block: l),
      TermsTableBlock t => _DefinitionsTable(block: t),
      TermsContactBlock c => _ContactCard(block: c),
    };
  }
}

class _Paragraph extends StatelessWidget {
  final TermsParagraphBlock block;

  const _Paragraph({required this.block});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LegalRichText(
        ref: block.ref,
        lead: block.lead,
        text: block.text,
        style: tt.bodyMedium?.copyWith(height: 1.65),
        textAlign: TextAlign.start,
      ),
    );
  }
}

/// The capitalised clauses (disclaimers, liability cap) — visually separated
/// so a reader cannot miss them.
class _CautionParagraph extends StatelessWidget {
  final TermsParagraphBlock block;

  const _CautionParagraph({required this.block});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withOpacity(.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10, top: 2),
            child: Icon(
              Icons.gavel_rounded,
              size: 18,
              color: cs.tertiary,
            ),
          ),
          Expanded(
            child: LegalRichText(
              ref: block.ref,
              lead: block.lead,
              text: block.text,
              style: tt.bodySmall?.copyWith(
                height: 1.6,
                letterSpacing: .1,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final TermsListBlock block;

  const _BulletList({required this.block});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in block.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsetsDirectional.only(end: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.marker.replaceAll('.', ''),
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LegalRichText(
                      text: item.text,
                      style: tt.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Definitions rendered as term/meaning pairs — readable on a phone, unlike a
/// real two-column table.
class _DefinitionsTable extends StatelessWidget {
  final TermsTableBlock block;

  const _DefinitionsTable({required this.block});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in block.rows)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.08),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    child: Text(
                      row.isNotEmpty ? row.first : '',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: LegalRichText(
                      text: row.length > 1 ? row[1] : '',
                      style: tt.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final TermsContactBlock block;

  const _ContactCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in block.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: LegalRichText(
                text: line,
                style: tt.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
