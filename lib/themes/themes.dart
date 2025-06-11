// lib/theme/themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tema untuk Mode Terang (Light Mode)
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.light).textTheme,
  ),
);

// Tema untuk Mode Gelap (Dark Mode)
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ),
);
