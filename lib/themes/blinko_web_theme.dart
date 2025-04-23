import 'package:flutter/material.dart';

/// Defines the custom theme for the Blinko web application.
/// Mimics the styling from the Next.js Blinko app.
class BlinkoWebTheme {
  // Define colors based on Blinko's Next.js theme (example values)
  static const Color primaryColor = Color(0xFF615FF7); // Example primary color
  static const Color backgroundColor = Color(0xFFF8F8FE); // Example background
  static const Color cardBackgroundColor = Colors.white; // Example card background
  static const Color textColor = Color(0xFF1A1A1A); // Example default text color
  static const Color textDescColor = Color(0xFF6B7280); // Example description text color

  static final ThemeData themeData = ThemeData(
    brightness: Brightness.light, // Default to light theme for now
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Inter', // Match the font used in Blinko Next.js if possible

    // Define ColorScheme
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: Color(0xFF00D2FF), // Example secondary color
      onSecondary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      background: backgroundColor,
      onBackground: textColor,
      surface: cardBackgroundColor, // Used for Cards, Dialogs, etc.
      onSurface: textColor,
    ),

    // Define TextTheme
    textTheme: const TextTheme(
      // Headline styles (adjust sizes as needed)
      headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: textColor),

      // Body text styles
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: textColor),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: textColor), // Default text
      bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12, color: textDescColor), // For descriptions or captions

      // Label styles (for buttons, etc.)
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
    ),

    // Define AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: cardBackgroundColor, // Example AppBar background
      foregroundColor: textColor, // Text and icons on AppBar
      elevation: 1.0, // Subtle shadow
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w500, color: textColor),
    ),

    // Define Card theme
    cardTheme: CardTheme(
      color: cardBackgroundColor,
      elevation: 0, // Blinko cards often have subtle borders or shadows, not high elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners like Blinko cards
        // Add border if needed: side: BorderSide(color: Colors.grey.shade300, width: 1)
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
    ),

    // Define Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),

    // Define Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      labelStyle: const TextStyle(color: textDescColor),
      hintStyle: const TextStyle(color: textDescColor),
    ),

    // Add other theme customizations here (FloatingActionButton, Dialogs, etc.)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),

    // Use Material 3 features
    useMaterial3: true,
  );

  // Optional: Define a dark theme as well
  // static final ThemeData darkThemeData = ThemeData(...);
}
