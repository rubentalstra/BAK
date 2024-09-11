import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

// LocaleBloc: Handles locale changes.
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc() : super(LocaleState(locale: const Locale('en'))) {
    on<LocaleChanged>((event, emit) {
      emit(LocaleState(locale: event.locale));
    });
  }
}
