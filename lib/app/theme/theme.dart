import 'package:flutter/material.dart';
import 'package:getx_demo1/app/theme/color_schemes.dart';

class AppTheme {
  static ThemeData light = ThemeData.light().copyWith(
    colorScheme: lightColorScheme,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static ThemeData dark = ThemeData.dark().copyWith(
    colorScheme: darkColorScheme,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
