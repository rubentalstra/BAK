import 'package:flutter/material.dart';
import 'colors.dart';

class AppThemes {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      primary: AppColors.lightPrimary,
      primaryContainer: AppColors.lightPrimaryVariant,
      secondary: AppColors.lightSecondary,
      surface: AppColors.lightSurface,
      onPrimary: AppColors.lightOnPrimary,
      onSecondary: AppColors.lightOnPrimary,
      onSurface: AppColors.lightOnPrimary,
      error: Colors.red.shade700,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    canvasColor: AppColors.cardBackground,
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
      backgroundColor: AppColors.lightSecondary,
      foregroundColor: AppColors.lightOnPrimary,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightOnPrimary),
      bodyMedium: TextStyle(color: AppColors.lightOnPrimary),
      displayLarge: TextStyle(color: AppColors.lightOnPrimary),
      headlineMedium: TextStyle(color: AppColors.lightOnPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.lightSecondary,
        backgroundColor: AppColors.lightPrimary,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.lightPrimary,
      textTheme: ButtonTextTheme.normal,
    ),
    dividerColor: Colors.grey.shade300,

    // Darker Card theme for dark mode
    cardTheme: CardTheme(
      color: AppColors.cardBackground, // Darker card background
      shadowColor:
          Colors.black.withOpacity(0.4), // Stronger shadow for contrast
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8.0),
    ),

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

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: AppColors.lightSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightPrimaryVariant,
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
          color: AppColors.lightAccent,
        ),
        hintStyle: TextStyle(
          color: Colors.grey,
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(
            AppColors.lightPrimary), // Set dropdown color
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

    dialogTheme: const DialogTheme(
      backgroundColor: AppColors.lightPrimaryVariant,
      titleTextStyle: TextStyle(
        color: AppColors.lightSecondary,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.lightOnPrimary,
        fontSize: 16.0,
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.lightSecondary;
        }
        return Colors.white;
      }),
    ),

    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.lightPrimaryVariant,
      dayStyle: TextStyle(color: AppColors.lightOnPrimary),
      yearStyle: TextStyle(color: AppColors.lightOnPrimary),
      weekdayStyle: TextStyle(color: AppColors.lightOnPrimary),
      headerBackgroundColor: AppColors.lightPrimary,
      headerForegroundColor: AppColors.lightSecondary,
    ),
  );
}
