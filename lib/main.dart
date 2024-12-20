import 'package:flutter/material.dart';
import 'features/navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define theme colors
  static const Color primaryYellow = Color(0xFFFFD700); // Golden yellow
  static const Color lightYellow = Color(0xFFFFF7D6); // Light yellow for backgrounds
  static const Color darkYellow = Color(0xFFB8860B); // Darker yellow for text
  static const Color accentYellow = Color(0xFFFFB700); // Accent yellow for buttons

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanEat',
      theme: ThemeData(
        // Basic theme colors
        primaryColor: primaryYellow,
        primarySwatch: MaterialColor(primaryYellow.value, {
          50: lightYellow,
          100: const Color(0xFFFFF3B0),
          200: const Color(0xFFFFE978),
          300: const Color(0xFFFFE040),
          400: accentYellow,
          500: primaryYellow,
          600: const Color(0xFFCCAC00),
          700: darkYellow,
          800: const Color(0xFF665600),
          900: const Color(0xFF332B00),
        }),
        scaffoldBackgroundColor: lightYellow,
        
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryYellow,
          foregroundColor: Colors.black87,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryYellow,
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: darkYellow.withOpacity(0.5)),
            ),
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkYellow.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkYellow.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentYellow),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Card theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: darkYellow.withOpacity(0.1)),
          ),
        ),

        // Bottom Navigation Bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: darkYellow,
          unselectedItemColor: Colors.black54,
          selectedIconTheme: IconThemeData(color: darkYellow),
          unselectedIconTheme: IconThemeData(color: Colors.black54),
          showUnselectedLabels: true,
        ),

        // Icon theme
        iconTheme: const IconThemeData(
          color: darkYellow,
        ),

        // Text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.black87),
          headlineMedium: TextStyle(color: Colors.black87),
          headlineSmall: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
        ),

        // Floating Action Button theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentYellow,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const NavigationScreen(),
    );
  }
}
