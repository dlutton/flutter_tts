import 'dart:js_interop';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

@JS('window.navigator.language')
external JSString get _browserPrimaryLanguageJS;

@JS('window.navigator.languages')
external JSArray<JSString>? get _browserLanguagesJS;

@JS('new Intl.DateTimeFormat().resolvedOptions().locale')
external JSString get _resolvedDateTimeFormatLocaleJS;

/// Fetches the browser's most specific preferred language and region code.
/// It prioritizes:
///   'navigator.language',
///   the first entry in 'navigator.languages', if available and more specific,
///   any further entry in 'navigator.languages', beginning with the non-specific
///   language code, plus '-' (e.g. "de-"), if available and more specific,
///   the 'Intl.DateTimeFormat().resolvedOptions().locale', if more specific.
///
/// Returns the language code as a String (e.g. "en-US", "de-DE", "de"),
/// or null if it cannot be determined.
/// Note: All these efforts may still only result in a language code without
/// a region code (e.g. "en", "de").
///
/// For the most targeted results, the user can ensure that the browser's
/// Settings/Language contain a preferred language entry containing both the
/// desired language and region (e.g. "English (United States)", "German (Germany)").
String? getBrowserLanguage() {
  String? lang;

  // Try navigator.language first
  try {
    final primaryLang = _browserPrimaryLanguageJS.toDart;
    if (kDebugMode) {
      debugPrint('getBrowserLanguage-primaryLang: $primaryLang');
    }
    if (primaryLang.contains('-')) return primaryLang;
    lang = primaryLang;
  } catch (_) {/* ignore */}

  // Try navigator.languages next
  try {
    final JSArray<JSString>? languagesJS = _browserLanguagesJS;
    if (languagesJS != null && languagesJS.toDart.isNotEmpty) {
      final topLang = languagesJS.toDart.first.toDart; // theo. highest priority
      if (kDebugMode) {
        debugPrint('getBrowserLanguage-topLang: $topLang');
      }
      if (lang != null && !lang.contains('-') && topLang.contains('-')) {
        return topLang;
      }
      lang ??= topLang;

      // lang is general (e.g., "de"), so look for a specific version (e.g., "de-DE")
      final List<String> browserLanguages =
          languagesJS.toDart.map((jsString) => jsString.toDart).toList();
      if (kDebugMode) {
        debugPrint('getBrowserLanguage-browserLanguages: $browserLanguages');
      }
      for (final langEntry in browserLanguages) {
        if (langEntry.startsWith('$lang-')) {
          if (kDebugMode) {
            debugPrint('Found more specific in languages: $langEntry');
          }
          lang = langEntry;
          break; // Found the first most specific match for lang
        }
      }
    }
  } catch (_) {/* ignore */}

  // As a last resort or alternative, try the Intl API
  try {
    final intlLang = _resolvedDateTimeFormatLocaleJS.toDart;
    if (kDebugMode) {
      debugPrint('getBrowserLanguage-intlLang: $intlLang');
    }
    if (lang != null && !lang.contains('-') && intlLang.contains('-')) {
      return intlLang;
    }
    lang ??= intlLang;
  } catch (_) {/* ignore */}

  return lang; // Return whatever we found
}
