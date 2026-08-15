import 'dart:convert';

import 'package:build4all_manager/features/legal/data/services/terms_repository.dart';
import 'package:build4all_manager/features/legal/domain/entities/terms_document.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The terms ship as static assets, so the guarantees worth pinning down are
/// that every translation carries the same document, and that a reader always
/// gets *some* copy of the terms even when their language is missing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bundle = rootBundle;

  Future<TermsDocument> load(String language) async {
    TermsRepository.clearCache();
    return TermsRepository(bundle: bundle).load(language);
  }

  group('bundled documents', () {
    test('every supported language ships a complete document', () async {
      for (final language in TermsRepository.supportedLanguages) {
        final document = await load(language);

        expect(document.language, language);
        expect(document.version, '1.0');
        expect(document.title, isNotEmpty);
        expect(document.sections, hasLength(20));
        expect(document.acknowledgement.checkbox, isNotEmpty);

        for (final section in document.sections) {
          expect(section.title, isNotEmpty, reason: '$language ${section.number}');
          expect(section.blocks, isNotEmpty, reason: '$language ${section.number}');
        }
      }
    });

    test('translations mirror the English structure block for block', () async {
      List<String> shapeOf(TermsDocument document) => [
            for (final section in document.sections)
              for (final block in section.blocks)
                '${section.number}:${block.runtimeType}',
          ];

      final english = shapeOf(await load('en'));

      for (final language in ['fr', 'ar']) {
        expect(shapeOf(await load(language)), english, reason: language);
      }
    });

    test('the definitions table keeps its term/meaning pairs', () async {
      final document = await load('en');
      final definitions = document.sections[1];
      final table = definitions.blocks.single as TermsTableBlock;

      expect(table.columns, ['Term', 'Meaning']);
      expect(table.rows, hasLength(8));
      expect(table.rows.first.first, 'Platform');
      expect(table.rows.every((row) => row.length == 2), isTrue);
    });

    test('capitalised clauses are flagged for emphasis', () async {
      final document = await load('en');
      final disclaimers = document.sections[13];

      expect(
        disclaimers.blocks.whereType<TermsParagraphBlock>().every(
              (block) => block.emphasised,
            ),
        isTrue,
      );
    });
  });

  group('language fallback', () {
    test('an untranslated language falls back to English', () async {
      final document = await load('de');

      expect(document.language, 'en');
      expect(document.sections, hasLength(20));
    });

    test('a missing asset falls back to English', () async {
      TermsRepository.clearCache();

      final document = await TermsRepository(bundle: _BrokenBundle()).load('fr');

      expect(document.language, 'en');
      expect(document.title, contains('Build4All'));
    });
  });
}

/// Serves the English asset only — everything else fails to load.
class _BrokenBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('terms_en.json')) return rootBundle.load(key);
    throw Exception('Asset not found: $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final data = await load(key);
    return utf8.decode(data.buffer.asUint8List());
  }
}
