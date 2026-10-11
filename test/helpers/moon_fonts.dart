import 'package:flutter/services.dart';

/// Loads the app's bundled fonts into the test engine, so golden images use
/// Fraunces, DM Sans and Gwendolyn instead of the test placeholder font.
Future<void> loadMoonFonts() async {
  const families = {
    'Fraunces72': [
      'Fraunces_72pt-Light',
      'Fraunces_72pt-Regular',
      'Fraunces_72pt-Italic',
    ],
    'Fraunces24': [
      'Fraunces_24pt-Regular',
      'Fraunces_24pt-Medium',
      'Fraunces_24pt-Italic',
      'Fraunces_24pt-MediumItalic',
    ],
    'DMSans': [
      'DMSans_14pt-Regular',
      'DMSans_14pt-Medium',
      'DMSans_14pt-SemiBold',
      'DMSans_14pt-Bold',
    ],
    'Gwendolyn': ['Gwendolyn-Bold'],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await loader.load();
  }
}
