import 'package:flutter/material.dart';
import 'dart:async';
import 'app_localization.dart';

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // Desteklenen dilleri burada belirt
    return ['tr', 'en', 'ar', 'de', 'fa', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    try {
      debugLog(
        "AppLocalizationDelegate: Dil yükleniyor: ${locale.languageCode}${locale.countryCode != null ? '-${locale.countryCode}' : ''}",
      );

      // VERY IMPORTANT: Flutter engine'in yüklenmesi için zaman tanı
      await Future.delayed(const Duration(milliseconds: 200));

      AppLocalization localization = AppLocalization(locale);
      bool loadSuccess = await localization.load();

      if (!loadSuccess) {
        debugLog("Dil yükleme başarısız, fallback kullanılıyor: tr");
        // Fallback olarak Türkçe'yi kullan
        localization = AppLocalization(const Locale('tr', 'TR'));
        await localization.load();
      }

      return localization;
    } catch (e) {
      debugLog("AppLocalizationDelegate.load error: $e");
      // Hata durumunda Türkçe'ye dön
      final fallback = AppLocalization(const Locale('tr', 'TR'));
      await fallback.load();
      return fallback;
    }
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

void debugLog(String message) {
  print('LOCALIZATION: $message');
}
