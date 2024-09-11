import 'package:flutter/material.dart';
import 'colors.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      primary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onPrimary: AppColors.lightOnPrimary,
      onSecondary: AppColors.lightOnPrimary,
      onSurface: AppColors.lightOnPrimary,
      error: Colors.red.shade700,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    appBarTheme: const AppBarTheme(
      color: AppColors.lightPrimary,
      iconTheme: IconThemeData(color: AppColors.lightOnPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.lightOnPrimary,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightOnPrimary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightAccent,
      foregroundColor: AppColors.lightOnPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightOnPrimary),
      bodyMedium: TextStyle(color: AppColors.lightOnPrimary),
      displayLarge: TextStyle(color: AppColors.lightOnPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.lightOnPrimary,
        backgroundColor: AppColors.lightPrimary,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.lightPrimary,
      textTheme: ButtonTextTheme.primary,
    ),
    dividerColor: Colors.grey.shade300,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      surface: AppColors.darkSurface,
      onPrimary: AppColors.darkOnPrimary,
      onSecondary: AppColors.darkOnPrimary,
      onSurface: AppColors.darkOnPrimary,
      error: Colors.red.shade900,
      onError: Colors.black,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: const AppBarTheme(
      color: AppColors.darkPrimary,
      iconTheme: IconThemeData(color: AppColors.darkOnPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.darkOnPrimary,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.darkOnPrimary),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: AppColors.darkOnPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkOnPrimary),
      bodyMedium: TextStyle(color: AppColors.darkOnPrimary),
      displayLarge: TextStyle(color: AppColors.darkOnPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.darkOnPrimary,
        backgroundColor: AppColors.darkPrimary,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.darkAccent,
      textTheme: ButtonTextTheme.primary,
    ),
    dividerColor: Colors.grey.shade600,
  );
}
