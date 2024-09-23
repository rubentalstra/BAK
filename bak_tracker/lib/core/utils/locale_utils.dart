class LocaleUtils {
  // Function to return the native language name based on the language code
  static String getLocaleName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English'; // Default language
      case 'nl':
        return 'Nederlands'; // Dutch
      case 'fr':
        return 'Français'; // French
      case 'de':
        return 'Deutsch'; // German
      case 'es':
        return 'Español'; // Spanish
      case 'it':
        return 'Italiano'; // Italian
      case 'pt':
        return 'Português'; // Portuguese
      case 'ru':
        return 'Русский'; // Russian
      case 'zh':
        return '中文'; // Chinese
      case 'ja':
        return '日本語'; // Japanese
      case 'ko':
        return '한국어'; // Korean
      case 'ar':
        return 'العربية'; // Arabic
      case 'hi':
        return 'हिन्दी'; // Hindi
      case 'bn':
        return 'বাংলা'; // Bengali
      case 'id':
        return 'Bahasa Indonesia'; // Indonesian
      case 'ms':
        return 'Bahasa Melayu'; // Malay
      case 'pl':
        return 'Polski'; // Polish
      case 'tr':
        return 'Türkçe'; // Turkish
      case 'vi':
        return 'Tiếng Việt'; // Vietnamese
      case 'th':
        return 'ไทย'; // Thai
      case 'el':
        return 'Ελληνικά'; // Greek
      case 'sv':
        return 'Svenska'; // Swedish
      case 'da':
        return 'Dansk'; // Danish
      case 'no':
        return 'Norsk'; // Norwegian
      case 'fi':
        return 'Suomi'; // Finnish
      case 'he':
        return 'עברית'; // Hebrew
      case 'hu':
        return 'Magyar'; // Hungarian
      case 'cs':
        return 'Čeština'; // Czech
      case 'sk':
        return 'Slovenčina'; // Slovak
      case 'ro':
        return 'Română'; // Romanian
      case 'uk':
        return 'Українська'; // Ukrainian
      case 'sr':
        return 'Српски'; // Serbian
      case 'hr':
        return 'Hrvatski'; // Croatian
      case 'bg':
        return 'Български'; // Bulgarian
      case 'et':
        return 'Eesti'; // Estonian
      case 'lt':
        return 'Lietuvių'; // Lithuanian
      case 'lv':
        return 'Latviešu'; // Latvian
      case 'sl':
        return 'Slovenščina'; // Slovenian
      case 'is':
        return 'Íslenska'; // Icelandic
      default:
        return languageCode;
    }
  }
}
