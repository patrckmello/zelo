import 'package:flutter/material.dart';

import 'zelo_colors.dart';

abstract final class ZeloTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ZeloColors.green,
      brightness: Brightness.light,
      primary: ZeloColors.green,
      secondary: ZeloColors.petroleumBlue,
      surface: Colors.white,
      error: ZeloColors.expiredRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ZeloColors.lightBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: ZeloColors.petroleumBlue,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: ZeloColors.petroleumBlue,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: ZeloColors.petroleumBlue,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: ZeloColors.textGray, height: 1.4),
        bodyMedium: TextStyle(color: ZeloColors.textGray, height: 1.4),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: ZeloColors.green.withValues(alpha: 0.16),
      ),
    );
  }
}
