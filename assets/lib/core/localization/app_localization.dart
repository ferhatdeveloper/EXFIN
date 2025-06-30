import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Çeviri işlemlerinin tamamlanıp tamamlanmadığını izlemek için
final translationsLoadedProvider = StateProvider<bool>((ref) => false);

// Dil sağlayıcı
final appLocalizationProvider = Provider<AppLocalization>((ref) {
  final locale = ref.watch(localeProvider);
  final appLocalization = AppLocalization(locale);

  // Çevirileri proaktif olarak yükle
  Future.microtask(() async {
    final success = await appLocalization.load();
    // Çeviri durumunu güncelle
    ref.read(translationsLoadedProvider.notifier).state = success;
  });

  return appLocalization;
});

// Dil sağlayıcı notifier
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('tr', 'TR')); // Türkçe varsayılan

  void setLocale(Locale locale) {
    state = locale;
  }
}

// Loglama yardımcı fonksiyonu
void debugLog(String message) {
  print(message);
}

// Mevcut dil dosyalarını kontrol eden yardımcı fonksiyon
Future<bool> doesLanguageFileExist(String fileName) async {
  try {
    await rootBundle.load('lib/core/localization/$fileName.json');
    return true;
  } catch (e) {
    return false;
  }
}

// Desteklenen diller
final Map<String, String> supportedLanguageFiles = {
  'tr': 'tr', // Türkçe
  'en': 'en', // İngilizce
  'ar': 'ar', // Arapça
  'ar-iq': 'ar-iq', // Irak Arapçası
  'de': 'de', // Almanca
  'fa': 'fa', // Farsça
  'ru': 'ru', // Rusça
  // Diğer desteklenen diller buraya eklenebilir
};

class AppLocalization {
  final Locale locale;
  Map<String, dynamic> _localizedValues = {};
  bool _isLoaded = false;
  static const String _fallbackLanguage = 'tr'; // Varsayılan dil Türkçe

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    try {
      final loc = Localizations.of<AppLocalization>(context, AppLocalization);
      if (loc == null) {
        debugLog("WARNING: AppLocalization.of() returned null, using fallback");
        // Fallback: Geçerli bir AppLocalization örneği oluştur
        return AppLocalization(const Locale('tr', 'TR'));
      }
      return loc;
    } catch (e) {
      debugLog("ERROR in AppLocalization.of(): $e");
      // Herhangi bir hata durumunda fallback
      return AppLocalization(const Locale('tr', 'TR'));
    }
  }

  Future<bool> load() async {
    try {
      // Önce dil kodunu belirle
      String langCode = locale.languageCode;
      String? countryCode = locale.countryCode;
      String langKey;

      // Kürtçe gibi özel durumlar için format oluştur
      if (langCode == 'ku' && countryCode != null) {
        langKey = '$langCode-${countryCode.toLowerCase()}';
      } else if (countryCode != null) {
        langKey = '$langCode-${countryCode.toLowerCase()}';
      } else {
        langKey = langCode;
      }

      debugLog('Dil dosyası yükleniyor: $langKey');

      // Destek durumunu kontrol et
      String? fileName = supportedLanguageFiles[langKey];
      if (fileName == null) {
        debugLog(
          'Bu dil ($langKey) desteklenmiyor, varsayılan dile ($_fallbackLanguage) dönülüyor',
        );
        fileName = _fallbackLanguage;
      }

      // Dosyanın varlığını kontrol et
      String filePath = 'lib/core/localization/$fileName.json';
      debugLog('Dosya yükleme denemesi: $filePath');

      // Dosyayı yüklemeye çalış
      try {
        String jsonString = await rootBundle.loadString(filePath);
        debugLog('Başarılı: $filePath');

        _localizedValues = json.decode(jsonString);
        debugLog(
          'JSON çözümlendi. İçerdiği anahtarlar: ${_localizedValues.keys.join(', ')}',
        );

        _isLoaded = true;
        return true;
      } catch (e) {
        // Dosya bulunamadı, varsayılan Türkçe'ye dön
        debugLog('Hata: $filePath - $e');
        debugLog('Varsayılan dil dosyasına dönülüyor');

        String fallbackPath = 'lib/core/localization/$_fallbackLanguage.json';

        try {
          String jsonString = await rootBundle.loadString(fallbackPath);
          debugLog('Fallback olarak Türkçe dil dosyası yüklendi');

          _localizedValues = json.decode(jsonString);
          debugLog(
            'Dosya içeriği yüklendi. İçerik uzunluğu: ${jsonString.length}',
          );

          _isLoaded = true;
          return true;
        } catch (innerError) {
          debugLog(
            'Kritik hata: Fallback dil dosyası da yüklenemedi: $innerError',
          );
          _isLoaded = false;
          return false;
        }
      }
    } catch (e) {
      debugLog('Dil dosyası yükleme hatası: $e');
      _isLoaded = false;
      return false;
    }
  }

  String translate(String key, {Map<String, String>? args}) {
    try {
      if (!_isLoaded) {
        debugLog('WARNING: Translations not loaded yet');
        return key; // If translations not loaded, return the key itself
      }

      // Split the key by dots to navigate through the nested JSON
      List<String> keys = key.split('.');
      dynamic value = _localizedValues;

      // Navigate through nested JSON using the key parts
      for (String k in keys) {
        if (value is Map && value.containsKey(k)) {
          value = value[k];
        } else {
          debugLog('Translation key not found: $key');
          return key; // Key not found, return the key itself
        }
      }

      // Handle string interpolation if args are provided
      String translatedText = value.toString();
      if (args != null) {
        args.forEach((argKey, argValue) {
          translatedText = translatedText.replaceAll('{$argKey}', argValue);
        });
      }

      return translatedText;
    } catch (e) {
      debugLog('Translation error: $e');
      return key; // On error, return the key itself
    }
  }

  // Kullanılabilir tüm dilleri döndür
  static List<Locale> supportedLocales() {
    return const [
      Locale('tr', 'TR'), // Türkçe
      Locale('en', 'US'), // İngilizce
      Locale('ar', 'SA'), // Arapça (Suudi Arabistan)
      Locale('ar', 'IQ'), // Irak Arapçası
      Locale('de', 'DE'), // Almanca
      Locale('fa', 'IR'), // Farsça (İran)
      Locale('ru', 'RU'), // Rusça
    ];
  }
}

// Delegate sınıfı
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) {
    // Kürtçe'yi açıkça reddet
    if (locale.languageCode == 'ku') {
      debugLog('Kürtçe dili (${locale.languageCode}) desteklenmiyor');
      return false;
    }

    // Desteklenen diller listesi
    return ['tr', 'en', 'ar', 'de', 'fa', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    print('AppLocalizationDelegate: Dil yükleniyor: ${locale.languageCode}');

    // VERY IMPORTANT: Ensure the Flutter engine has a chance to load first
    await Future.delayed(Duration(milliseconds: 200));

    AppLocalization localization = AppLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}
