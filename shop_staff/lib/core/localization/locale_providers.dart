import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedLocales = <Locale>[Locale('zh'), Locale('ja'), Locale('en')];

class LocaleController extends StateNotifier<Locale?> {
  LocaleController() : super(null);

  void update(Locale locale) => state = locale;

  void useSystemLocale() => state = null;
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale?>(
      (ref) => LocaleController(),
    );

bool isSupportedLocale(Locale locale) {
  return supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );
}

Locale? localeFromSettingsCode(String? code) {
  switch (code?.trim().toLowerCase()) {
    case 'zh':
      return const Locale('zh');
    case 'ja':
      return const Locale('ja');
    case 'en':
      return const Locale('en');
    default:
      return null;
  }
}

String? localeToSettingsCode(Locale? locale) {
  if (locale == null) {
    return null;
  }
  final code = locale.languageCode.trim().toLowerCase();
  return isSupportedLocale(Locale(code)) ? code : null;
}

String? localeToShopLanguageOverride(Locale? locale) {
  switch (locale?.languageCode.toLowerCase()) {
    case 'zh':
      return 'CN';
    case 'ja':
      return 'JP';
    case 'en':
      return 'EN';
    default:
      return null;
  }
}
