import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_localization.dart';

/// Otomatik çeviri yapan text widget'ı
class LocalizedText extends ConsumerWidget {
  final String textKey;
  final Map<String, String>? args;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final TextWidthBasis? textWidthBasis;

  const LocalizedText(
    this.textKey, {
    Key? key,
    this.args,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.textWidthBasis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Context üzerinden AppLocalization'a erişim sağla
    final appLocalization = AppLocalization.of(context);

    // Varsayılan olarak anahtar değerini kullan
    String displayText = textKey;

    // Eğer nokta içeren bir anahtar ise, çeviri yap
    if (textKey.contains('.')) {
      try {
        // Context üzerinden erişimi kullan
        displayText = appLocalization.translate(textKey, args: args);

        // Eğer çeviri anahtarın kendisi ise, bu çevirinin bulunamadığı anlamına gelir
        if (displayText == textKey) {
          print('Çeviri bulunamadı: $textKey');
        }
      } catch (e) {
        print('LocalizedText çeviri hatası: $e');
        // Hata durumunda anahtarı döndür
        displayText = textKey;
      }
    }

    // Doğrudan metin göster
    return Text(
      displayText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      textWidthBasis: textWidthBasis,
    );
  }
}

/// String uzantısı ile kolay çeviri
extension TranslationExtension on String {
  String tr(BuildContext context, {Map<String, String>? args}) {
    // Eğer nokta içeren bir anahtar ise, çeviri yap
    if (contains('.')) {
      try {
        // Context üzerinden erişimi dene
        final appLocalization = AppLocalization.of(context);
        return appLocalization.translate(this, args: args);
      } catch (e) {
        print('String.tr çeviri hatası: $e');
        // Hata durumunda, Consumer ile Riverpod erişimi sağlayan bir widget kullanın
        print('String.tr yerine LocalizedText widget kullanılması önerilir');
        return this;
      }
    }
    return this;
  }
}
