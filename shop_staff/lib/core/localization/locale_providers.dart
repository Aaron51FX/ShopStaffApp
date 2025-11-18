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
