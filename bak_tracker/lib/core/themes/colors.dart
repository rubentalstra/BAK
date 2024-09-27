import 'package:flutter/material.dart';

class AppColors {
  // Primary colors based on your main color and accent from the logo
  static const Color lightPrimary =
      Color.fromARGB(255, 29, 40, 45); // Main color
  static const Color lightPrimaryVariant =
      Color(0xFF3D4A51); // Slightly lighter variant for contrast
  static const Color lightSecondary =
      Color.fromARGB(255, 218, 164, 66); // Accent color from the logo
  static const Color lightAccent =
      Color(0xFFF5C76E); // Lighter accent to complement the logo accent

  // Background and surface colors
  static const Color lightBackground =
      Color(0xFFE1E5E7); // Soft neutral background
  static const Color lightSurface =
      Color(0xFFF0F4F8); // Soft off-white/light grey for cards (new color)

  // Text and icon colors
  static const Color lightOnPrimary =
      Color(0xFFFAFAFA); // Light color for text/icons on primary backgrounds
  static const Color lightOnSecondary = Color(
      0xFF1D1D1D); // Dark color for text/icons on secondary or accent backgrounds

  // Additional accent tones
  static const Color lightAccentVariant =
      Color(0xFFD98C4B); // Slightly darker variant of the accent for highlights
  static const Color lightDivider =
      Color(0xFFB0BEC5); // Subtle color for dividers

  // New card background color
  static const Color cardBackground = Color(0xFF2B343B);
}
