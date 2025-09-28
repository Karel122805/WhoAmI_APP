import 'package:flutter/material.dart';

/// Colores base
const kPurple = Color(0xFFD6A7F4);
const kBlue   = Color(0xFF9ED3FF);   // azul exacto del mock
const kInk    = Color(0xFF111111);
const kGrey1  = Color(0xFF6B7280);

// Campos
const kFieldBorder = Color(0xFFE5E7EB);
const kFieldFill   = Color(0xFFF7F8FA);

final appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: kInk,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: kInk, fontSize: 22, fontWeight: FontWeight.w700,
    ),
  ),

  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: kInk),
    titleLarge:    TextStyle(fontSize: 22, fontWeight: FontWeight.w700,  color: kInk),
    bodyMedium:    TextStyle(fontSize: 16, color: kInk),
    labelLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kInk),
  ),

  inputDecorationTheme: InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: kFieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: const TextStyle(color: kGrey1),
    labelStyle: const TextStyle(color: kGrey1),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kFieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBlue, width: 1.4),
    ),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      elevation: 0,
      foregroundColor: kInk, // texto negro
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),

  iconTheme: const IconThemeData(color: kInk),
);

/// Helpers para botones tipo “pastilla”
ButtonStyle pillBlue() => FilledButton.styleFrom(backgroundColor: kBlue);
ButtonStyle pillLav()  => FilledButton.styleFrom(backgroundColor: kPurple);
ButtonStyle pill(Color c) => FilledButton.styleFrom(backgroundColor: c);

/// Estilo del texto “BIENVENIDO A” usado en el splash
const welcomeKicker = TextStyle(
  letterSpacing: 1.5,
  color: kGrey1,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);
