import 'package:flutter/material.dart';

/// Defines the custom theme for the Blinko web application.
/// Mimics the styling from the Next.js Blinko app.
class BlinkoWebTheme {
  // --- Light Theme Colors ---
  static const Color primaryColorLight = Color(0xFF615FF7);
  static const Color backgroundColorLight = Color(0xFFF8F8FE);
  static const Color cardBackgroundColorLight = Colors.white;
  static const Color textColorLight = Color(0xFF1A1A1A);
  static const Color textDescColorLight = Color(0xFF6B7280);
  static const Color secondaryColorLight = Color(0xFF00D2FF);

  // --- Dark Theme Colors (Example) ---
  static const Color primaryColorDark = Color(0xFF7C7AFF); // Lighter purple
  static const Color backgroundColorDark = Color(0xFF121212); // Dark background
  static const Color cardBackgroundColorDark = Color(
    0xFF1E1E1E,
  ); // Slightly lighter dark
  static const Color textColorDark = Color(0xFFE0E0E0); // Light grey text
  static const Color textDescColorDark = Color(0xFF9E9E9E); // Medium grey text
  static const Color secondaryColorDark = Color(
    0xFF00B8D4,
  ); // Slightly muted cyan

  // --- Light Theme Definition ---
  static final ThemeData themeData = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColorLight,
    scaffoldBackgroundColor: backgroundColorLight,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryColorLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0DFFF), // Light purple container
      onPrimaryContainer: Color(0xFF1A1A1A),
      secondary: secondaryColorLight,
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFFB3F3FF), // Light cyan container
      onSecondaryContainer: Color(0xFF1A1A1A),
      error: Colors.redAccent,
      onError: Colors.white,
      surface: cardBackgroundColorLight,
      onSurface: textColorLight,
      outline: Colors.grey, // Default outline color
    ),
    textTheme: _buildTextTheme(textColorLight, textDescColorLight),
    appBarTheme: _buildAppBarTheme(cardBackgroundColorLight, textColorLight),
    cardTheme: _buildCardTheme(cardBackgroundColorLight),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      primaryColorLight,
      Colors.white,
    ),
    textButtonTheme: _buildTextButtonTheme(primaryColorLight),
    inputDecorationTheme: _buildInputDecorationTheme(
      primaryColorLight,
      Colors.grey.shade400,
      textDescColorLight,
    ),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(
      primaryColorLight,
      Colors.white,
    ),
    navigationRailTheme: _buildNavigationRailThemeData(
      backgroundColorLight,
      primaryColorLight,
      textColorLight,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: cardBackgroundColorLight,
    ),
    listTileTheme: const ListTileThemeData(iconColor: textDescColorLight),
    iconTheme: const IconThemeData(
      color: textDescColorLight,
    ), // Default icon color
    useMaterial3: true,
  );

  // --- Dark Theme Definition ---
  static final ThemeData darkThemeData = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColorDark,
    scaffoldBackgroundColor: backgroundColorDark,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColorDark,
      onPrimary: Colors.black, // Text on primary color
      primaryContainer: Color(0xFF3A3A8A), // Darker purple container
      onPrimaryContainer: Color(0xFFE0E0E0),
      secondary: secondaryColorDark,
      onSecondary: Colors.black,
      secondaryContainer: Color(0xFF005A6A), // Darker cyan container
      onSecondaryContainer: Color(0xFFE0E0E0),
      error: Colors.redAccent, // Keep error color consistent?
      onError: Colors.white,
      surface: cardBackgroundColorDark, // Use card background for surface
      onSurface: textColorDark,
      outline: Color(0xFF616161), // Darker outline
    ),
    textTheme: _buildTextTheme(textColorDark, textDescColorDark),
    appBarTheme: _buildAppBarTheme(cardBackgroundColorDark, textColorDark),
    cardTheme: _buildCardTheme(cardBackgroundColorDark),
    elevatedButtonTheme: _buildElevatedButtonTheme(
      primaryColorDark,
      Colors.black,
    ),
    textButtonTheme: _buildTextButtonTheme(primaryColorDark),
    inputDecorationTheme: _buildInputDecorationTheme(
      primaryColorDark,
      Colors.grey.shade700,
      textDescColorDark,
    ),
    floatingActionButtonTheme: _buildFloatingActionButtonTheme(
      primaryColorDark,
      Colors.black,
    ),
    navigationRailTheme: _buildNavigationRailThemeData(
      backgroundColorDark,
      primaryColorDark,
      textColorDark,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: cardBackgroundColorDark,
    ),
    listTileTheme: const ListTileThemeData(iconColor: textDescColorDark),
    iconTheme: const IconThemeData(
      color: textDescColorDark,
    ), // Default icon color for dark theme
    useMaterial3: true,
  );

  // --- Helper methods to build theme components ---

  static TextTheme _buildTextTheme(Color defaultColor, Color descColor) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: defaultColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: defaultColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: defaultColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: defaultColor,
      ), // For AppBar titles etc.
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: defaultColor,
      ), // For Card titles etc.
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: defaultColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        color: defaultColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: defaultColor,
      ), // Default text
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        color: descColor,
      ), // For descriptions or captions
      labelLarge: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ), // Button text color set by button theme
      labelMedium: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color bgColor, Color fgColor) {
    return AppBarTheme(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 1.0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: fgColor,
      ),
      iconTheme: IconThemeData(
        color: fgColor,
      ), // Ensure icons match foreground color
    );
  }

  static CardTheme _buildCardTheme(Color cardColor) {
    return CardTheme(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // Optionally add a subtle border for dark theme if needed
        // side: BorderSide(color: brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300, width: 1)
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    Color bgColor,
    Color fgColor,
  ) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Color fgColor) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: fgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    Color primaryColor,
    Color borderColor,
    Color hintColor,
  ) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        // Ensure enabled state has the correct border color
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
      labelStyle: TextStyle(color: hintColor),
      hintStyle: TextStyle(color: hintColor),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Consistent padding
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(
    Color bgColor,
    Color fgColor,
  ) {
    return FloatingActionButtonThemeData(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
    );
  }

  static NavigationRailThemeData _buildNavigationRailThemeData(
    Color bgColor,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return NavigationRailThemeData(
      backgroundColor: bgColor,
      selectedIconTheme: IconThemeData(color: selectedColor),
      unselectedIconTheme: IconThemeData(
        color: unselectedColor.withOpacity(0.7),
      ),
      selectedLabelTextStyle: TextStyle(
        color: selectedColor,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: unselectedColor.withOpacity(0.7),
        fontFamily: 'Inter',
      ),
      indicatorColor: selectedColor.withOpacity(
        0.1,
      ), // Subtle indicator behind selected item
    );
  }
}
