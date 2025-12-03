// main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OfflineChatApp());
}

class OfflineChatApp extends StatelessWidget {
  const OfflineChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const creamBackground = Color(0xFFF7F3EB);
    const darkCup = Color(0xFF2F3B37);
    const leafGreen = Color(0xFF4BA674);

    final baseScheme = ColorScheme.fromSeed(
      seedColor: darkCup,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Caflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: baseScheme.copyWith(
          primary: darkCup,
          secondary: leafGreen,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: creamBackground,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}