import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFFC2185B);

  static ThemeData get light => _base(Brightness.light);

  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
    );
  }
}
