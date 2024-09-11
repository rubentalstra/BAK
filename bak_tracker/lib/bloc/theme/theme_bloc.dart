import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

// Theme Event
abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeMode themeMode;

  ThemeChanged({required this.themeMode});
}

class ThemeState {
  final ThemeMode themeMode;

  ThemeState({required this.themeMode});
}

// Theme Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(themeMode: ThemeMode.system)) {
    on<ThemeChanged>((event, emit) {
      emit(ThemeState(themeMode: event.themeMode));
    });
  }
}
