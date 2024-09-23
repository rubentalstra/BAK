import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LocaleEvent: This is triggered to change the app’s locale.
abstract class LocaleEvent {}

class LocaleChanged extends LocaleEvent {
  final Locale locale;

  LocaleChanged({required this.locale});
}

// LocaleState: Represents the current locale.
class LocaleState {
  final Locale locale;

  LocaleState({required this.locale});
}

// LocaleBloc: Handles locale changes and stores them persistently.
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String localeKey = 'app_locale';

  LocaleBloc() : super(LocaleState(locale: const Locale('en'))) {
    _loadLocale();
    on<LocaleChanged>((event, emit) async {
      emit(LocaleState(locale: event.locale));
      await _saveLocale(event.locale);
    });
  }

  // Load saved locale from SharedPreferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(localeKey);
    if (localeCode != null) {
      add(LocaleChanged(locale: Locale(localeCode)));
    }
  }

  // Save selected locale to SharedPreferences
  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localeKey, locale.languageCode);
  }
}
