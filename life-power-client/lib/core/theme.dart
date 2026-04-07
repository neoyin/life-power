import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.teal,
    colorScheme: ColorScheme.dark(
      primary: Colors.teal,
      secondary: Colors.blueAccent,
      background: Colors.grey[900]!,
      surface: Colors.grey[800]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.teal,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[400],
      ),
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.teal,
    colorScheme: ColorScheme.light(
      primary: Colors.teal,
      secondary: Colors.blueAccent,
      background: Colors.white,
      surface: Colors.grey[100]!,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.grey[100],
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.teal,
      textTheme: ButtonTextTheme.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ),
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
  );
  
  // 能量等级颜色 - 使用设计规范品牌颜色
  static Color getEnergyColor(String level) {
    switch (level) {
      case 'high':
        return const Color(0xFF006F1D); // 活力绿 Vitality Green
      case 'medium':
        return const Color(0xFFF1B52D); // 宁静黄 Mellow Yellow
      case 'low':
        return const Color(0xFF9C4343); // 警示红 Critical Red
      default:
        return const Color(0xFF535F6F); // 沉静灰蓝 Exhausted Grey/Blue
    }
  }

  // 根据能量百分比获取能量等级
  static String getEnergyLevel(int score) {
    if (score >= 70) {
      return 'high';
    } else if (score >= 40) {
      return 'medium';
    } else if (score >= 20) {
      return 'low';
    } else {
      return 'exhausted';
    }
  }
}
