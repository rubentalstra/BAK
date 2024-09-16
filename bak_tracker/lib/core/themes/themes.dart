import 'package:flutter/material.dart';
import 'colors.dart';

class AppThemes {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
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
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.lightPrimaryVariant,
    appBarTheme: const AppBarTheme(
      color: AppColors.lightPrimary,
      iconTheme: IconThemeData(color: AppColors.lightSecondary),
      titleTextStyle: TextStyle(
        color: AppColors.lightSecondary,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.lightSecondary),
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
        foregroundColor: AppColors.lightAccent,
        backgroundColor: AppColors.lightPrimary,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.lightPrimary,
      textTheme: ButtonTextTheme.accent,
    ),
    dividerColor: Colors.grey.shade300,

//tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.lightSecondary,
      unselectedLabelColor: Colors.grey,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightSecondary,
            width: 2.0,
          ),
        ),
      ),
    ),

    // Add DropdownMenu Theme
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: AppColors.lightSecondary,
        fontSize: 18.0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12.0),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.lightSurface),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        elevation: WidgetStateProperty.all(8),
      ),
    ),
  );
}
