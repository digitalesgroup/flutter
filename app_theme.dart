//lib/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Actualizados para que coincidan más con el diseño verde
  static const Color primaryColor = Color(0xFF029B83); // Verde primario
  static const Color accentColor = Color(0xFF2196F3); // Azul como acento
  static const Color successColor = Color(0xFF029B83);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF7F8C8D);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Colores para el dashboard
  static const Color sidebarColor = Color(0xFF029B83);
  static const Color dashboardBlue = Color(0xFF2196F3);
  static const Color dashboardOrange = Color(0xFFFF9800);
  static const Color dashboardPurple = Color(0xFF9C27B0);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14.0,
    color: lightTextColor,
  );

  // Theme Data
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      titleTextStyle: headingStyle.copyWith(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: headingStyle,
      titleMedium: subheadingStyle,
      bodyMedium: bodyStyle,
      bodySmall: subtitleStyle,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: sidebarColor,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.7)),
      selectedLabelTextStyle: const TextStyle(color: Colors.white),
      unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    cardTheme: CardTheme(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      titleTextStyle: headingStyle.copyWith(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textTheme: TextTheme(
      headlineMedium: headingStyle.copyWith(color: Colors.white),
      titleMedium: subheadingStyle.copyWith(color: Colors.white),
      bodyMedium: bodyStyle.copyWith(color: Colors.white),
      bodySmall: subtitleStyle.copyWith(color: Colors.white70),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedIconTheme: const IconThemeData(color: primaryColor),
      unselectedIconTheme: const IconThemeData(color: Colors.grey),
      selectedLabelTextStyle: const TextStyle(color: primaryColor),
      unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
    ),
  );
}
