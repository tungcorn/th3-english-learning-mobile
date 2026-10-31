import 'package:flutter/material.dart';

import '../domain/phoneme/phoneme_aligner.dart';

const Color _lagoon = Color(0xFF0B6E75);
const Color marigold = Color(0xFFF5A524);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _lagoon,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarTheme(centerTitle: false),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, height: 1.25),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
    ),
  );
}

/// Colors of a phoneme tile. Status is also shown by the sound written below
/// the tile, so it never depends on color alone.
({Color background, Color foreground}) phonemeColors(
  BuildContext context,
  PhonemeStatus status,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (status) {
    PhonemeStatus.correct =>
      dark
          ? (
              background: const Color(0xFF12402F),
              foreground: const Color(0xFFB5F0D3),
            )
          : (
              background: const Color(0xFFD9F3E6),
              foreground: const Color(0xFF0D5C40),
            ),
    PhonemeStatus.near =>
      dark
          ? (
              background: const Color(0xFF4A3300),
              foreground: const Color(0xFFFFDDA0),
            )
          : (
              background: const Color(0xFFFFEBC4),
              foreground: const Color(0xFF6B4400),
            ),
    PhonemeStatus.wrong || PhonemeStatus.missing || PhonemeStatus.extra =>
      dark
          ? (
              background: const Color(0xFF5A1A17),
              foreground: const Color(0xFFFFD2CD),
            )
          : (
              background: const Color(0xFFFBDAD6),
              foreground: const Color(0xFF8C1D18),
            ),
  };
}
