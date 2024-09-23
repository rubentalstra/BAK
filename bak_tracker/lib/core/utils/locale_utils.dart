class LocaleUtils {
  // Function to return the native language name based on the language code
  static String getLocaleName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'nl':
        return 'Nederlands';
      // Add more languages if necessary
      default:
        return languageCode;
    }
  }
}
