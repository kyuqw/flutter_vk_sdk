import 'package:flutter/material.dart';

class VkTheme {
  static final colors = _C();

  static ThemeData getTheme(BuildContext context) {
    return ThemeData(
      primaryColor: Colors.white,
      appBarTheme: AppBarTheme(elevation: 1.0),
      canvasColor: Colors.white,
      primaryIconTheme: IconThemeData(color: Colors.grey),
      iconTheme: IconThemeData(color: Colors.grey),
    );
  }
}

class _C {}
