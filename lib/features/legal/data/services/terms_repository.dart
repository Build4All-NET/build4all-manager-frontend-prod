import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/terms_document.dart';

/// Loads the Terms & Conditions from the bundled JSON assets.
///
/// The terms are static app data — there is no backend endpoint behind them,
/// so the document is read once per language and kept in memory afterwards.
class TermsRepository {
  TermsRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Languages that have a translated copy of the document.
  static const supportedLanguages = {'en', 'fr', 'ar'};

  /// The language the document was originally drafted in; it is also the
  /// fallback for any locale we do not translate, and the version that
  /// prevails in case of conflict (Section 19.10).
  static const fallbackLanguage = 'en';

  static final Map<String, TermsDocument> _cache = {};

  static String _assetFor(String language) => 'assets/legal/terms_$language.json';

  /// Returns the document for [languageCode], falling back to English when the
  /// language is not translated or its asset cannot be read.
  Future<TermsDocument> load(String languageCode) async {
    final language = supportedLanguages.contains(languageCode)
        ? languageCode
        : fallbackLanguage;

    final cached = _cache[language];
    if (cached != null) return cached;

    try {
      final document = await _read(language);
      return _cache[language] = document;
    } catch (_) {
      if (language == fallbackLanguage) rethrow;

      final cachedFallback = _cache[fallbackLanguage];
      if (cachedFallback != null) return cachedFallback;

      final fallback = await _read(fallbackLanguage);
      return _cache[fallbackLanguage] = fallback;
    }
  }

  Future<TermsDocument> _read(String language) async {
    final raw = await _bundle.loadString(_assetFor(language));
    return TermsDocument.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  /// Test seam — drops the in-memory copies.
  static void clearCache() => _cache.clear();
}
