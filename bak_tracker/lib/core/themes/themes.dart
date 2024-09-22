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
      textTheme: ButtonTextTheme.normal,
    ),
    dividerColor: Colors.grey.shade300,

    // Tab bar theme
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

    // DropdownMenuTheme for better readability
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: AppColors.lightAccent, // Text color for better contrast
        fontSize: 18.0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor:
            AppColors.lightPrimaryVariant, // Background color for input field
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightSecondary, width: 2.0),
        ),
        contentPadding: EdgeInsets.all(12.0),
        labelStyle: TextStyle(
          color: AppColors.lightAccent, // Label text color for contrast
        ),
        hintStyle: TextStyle(
          color: Colors.grey, // Hint text color for better readability
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.lightAccent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        elevation: WidgetStateProperty.all(8),
      ),
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.lightPrimaryVariant,
      textStyle: TextStyle(color: AppColors.lightAccent),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(AppColors.lightPrimary),
      overlayColor: WidgetStateProperty.all(AppColors.lightAccentVariant),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.lightPrimary,
      contentTextStyle: TextStyle(color: AppColors.lightAccent),
      actionTextColor: AppColors.lightAccent,
    ),
  );
}
