import 'package:flutter/material.dart';

class ThemeConfig {
  // สีหลักของแอป
  static const Color primaryColor = Color(0xFF2196F3); // สีฟ้า
  static const Color secondaryColor = Color(0xFF03A9F4); // สีฟ้าอ่อน
  static const Color accentColor = Color(0xFF4CAF50); // สีเขียว
  
  // ธีมแบบสว่าง
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    fontFamily: 'Kanit', // ฟอนต์ภาษาไทยที่ใช้งานได้ดี
    scaffoldBackgroundColor: Colors.grey[50],
    dividerColor: Colors.grey[300],
  );
  
  // ธีมแบบมืด
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: const Color(0xFF303030),
      background: const Color(0xFF202020),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF303030),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[400],
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    fontFamily: 'Kanit', // ฟอนต์ภาษาไทยที่ใช้งานได้ดี
    scaffoldBackgroundColor: const Color(0xFF121212),
    dividerColor: Colors.grey[800],
  );
}