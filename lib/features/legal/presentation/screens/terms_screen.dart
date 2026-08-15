import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/services/terms_repository.dart';
import '../../domain/entities/terms_document.dart';
import '../widgets/terms_block_view.dart';

/// Full-screen reader for the Terms & Conditions.
///
/// Opened in two modes:
///  * read-only (from the profile screen), and
///  * acceptance mode (from registration), where the screen pops `true` once
///    the user has scrolled through the document and agreed.
class TermsScreen extends StatefulWidget {
  /// Shows the accept / decline bar and requires the reader to reach the end
  /// of the document before agreeing.
  final bool requireAcceptance;

  /// Pre-checked state when the user re-opens terms they already accepted.
  final bool alreadyAccepted;

  const TermsScreen({
    super.key,
    this.requireAcceptance = false,
    this.alreadyAccepted = false,
  });

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _scroll = ScrollController();
  final _repository = TermsRepository();
  final _sectionKeys = <String, GlobalKey>{};

  Future<TermsDocument>? _future;
  String? _loadedLanguage;

  /// Whether the reader has seen the end of the document.
  bool _reachedEnd = false;

  /// 0..1 reading progress, drawn under the app bar.
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    // Someone re-opening terms they already accepted should not have to scroll
    // through the whole document again to confirm.
    if (widget.alreadyAccepted) {
      _reachedEnd = true;
      _progress = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (language != _loadedLanguage) {
      _loadedLanguage = language;
      _future = _repository.load(language);
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;
    final max = position.maxScrollExtent;

    // A document shorter than the viewport counts as fully read.
    final progress = max <= 0 ? 1.0 : (position.pixels / max).clamp(0.0, 1.0);
    final reachedEnd = max <= 0 || position.pixels >= max - 24;

    if (progress != _progress || reachedEnd != _reachedEnd) {
      setState(() {
        _progress = progress;
        _reachedEnd = _reachedEnd || reachedEnd;
      });
    }
  }

  /// Content can be shorter than the viewport (small documents, large screens),
  /// in which case no scroll event ever fires.
  void _checkIfAlreadyAtEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0 && !_reachedEnd) {
        setState(() {
          _reachedEnd = true;
          _progress = 1;
        });
      }
    });
  }

  void _jumpToSection(String number) {
    final key = _sectionKeys[number];
    final target = key?.currentContext;
    if (target == null) return;

    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _accept() => Navigator.of(context).pop(true);

  void _close() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.terms_title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _close,
          tooltip: l10n.cancel,
        ),
        bottom: widget.requireAcceptance
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: cs.outlineVariant.withOpacity(.4),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: FutureBuilder<TermsDocument>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final document = snapshot.data;
            if (document == null) {
              return _ErrorState(
                message: l10n.terms_load_error,
                retryLabel: l10n.retry,
                onRetry: () => setState(() {
                  _future = _repository.load(_loadedLanguage ?? 'en');
                }),
              );
            }

            _checkIfAlreadyAtEnd();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _TermsBody(
                  document: document,
                  controller: _scroll,
                  sectionKeys: _sectionKeys,
                  onSectionTap: _jumpToSection,
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: widget.requireAcceptance
          ? _AcceptBar(
              enabled: _reachedEnd,
              onAccept: _accept,
              onDecline: _close,
            )
          : null,
    );
  }
}

class _TermsBody extends StatelessWidget {
  final TermsDocument document;
  final ScrollController controller;
  final Map<String, GlobalKey> sectionKeys;
  final ValueChanged<String> onSectionTap;

  const _TermsBody({
    required this.document,
    required this.controller,
    required this.sectionKeys,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DocumentHeader(document: document),
          const SizedBox(height: 14),

          if (document.language != TermsRepository.fallbackLanguage) ...[
            _TranslationNotice(message: l10n.terms_english_notice),
            const SizedBox(height: 14),
          ],

          _ContentsCard(
            title: l10n.terms_contents,
            sections: document.sections,
            onTap: onSectionTap,
          ),
          const SizedBox(height: 18),

          for (final section in document.sections) ...[
            _SectionCard(
              key: sectionKeys.putIfAbsent(section.number, GlobalKey.new),
              section: section,
            ),
            const SizedBox(height: 14),
          ],

          _AcknowledgementCard(acknowledgement: document.acknowledgement),
        ],
      ),
    );
  }
}

class _DocumentHeader extends StatelessWidget {
  final TermsDocument document;

  const _DocumentHeader({required this.document});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            cs.primary.withOpacity(.14),
            cs.primary.withOpacity(.04),
          ],
        ),
        border: Border.all(color: cs.primary.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  document.title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.numbers_rounded,
                label: l10n.terms_version_label,
                value: document.version,
              ),
              _MetaChip(
                icon: Icons.event_available_outlined,
                label: l10n.terms_effective_label,
                value: document.effectiveDate,
              ),
              _MetaChip(
                icon: Icons.update_rounded,
                label: l10n.terms_updated_label,
                value: document.lastUpdated,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TranslationNotice extends StatelessWidget {
  final String message;

  const _TranslationNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.translate_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentsCard extends StatelessWidget {
  final String title;
  final List<TermsSection> sections;
  final ValueChanged<String> onTap;

  const _ContentsCard({
    required this.title,
    required this.sections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.list_alt_rounded, color: cs.primary),
          title: Text(
            title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            for (final section in sections)
              InkWell(
                onTap: () => onTap(section.number),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          section.number,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          section.title,
                          style: tt.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final TermsSection section;

  const _SectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    section.number,
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      section.title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final block in section.blocks) TermsBlockView(block: block),
          ],
        ),
      ),
    );
  }
}

class _AcknowledgementCard extends StatelessWidget {
  final TermsAcknowledgement acknowledgement;

  const _AcknowledgementCard({required this.acknowledgement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  acknowledgement.title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            acknowledgement.text,
            style: tt.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _AcceptBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _AcceptBar({
    required this.enabled,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(.7)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: enabled
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.keyboard_double_arrow_down_rounded,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l10n.terms_scroll_hint,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.terms_decline_action,
                    type: AppButtonType.outline,
                    expand: true,
                    onPressed: onDecline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: l10n.terms_accept_action,
                    expand: true,
                    trailing: const Icon(Icons.check_rounded),
                    onPressed: enabled ? onAccept : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(
              label: retryLabel,
              type: AppButtonType.outline,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
