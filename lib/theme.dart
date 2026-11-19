import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens from the approved UI design (Eventify-AI-Design), the same
/// values the web app uses in public/css/app.css, so both apps look alike.
class C {
  static const bg = Color(0xFFF5EFE4); // page (cream)
  static const surface = Color(0xFFFFFBF4); // cards
  static const fill = Color(0xFFEFE7D8); // chips, subtle fills
  static const ink = Color(0xFF1E1A15); // text + dark surfaces
  static const ink2 = Color(0xFF3E362E);
  static const muted = Color(0xFF6B6158);
  static const line = Color(0xFFE3D9C8);
  static const accent = Color(0xFFB3401E); // terracotta
  static const accentSoft = Color(0xFFF6DCD2);
  static const green = Color(0xFF1F5A45);
  static const greenSoft = Color(0xFFDCEBE3);
  static const greenInk = Color(0xFF143D2F);
  static const gold = Color(0xFFE3A72F);
  static const goldSoft = Color(0xFFF7E7C2);
  static const goldInk = Color(0xFF6B4A0E);
  static const dark2 = Color(0xFF2A241D);
  static const darkLine = Color(0xFF3A3229);
  static const darkMuted = Color(0xFFCFC4B4);
  static const danger = Color(0xFF8F2A10);
}

/// Text styles: Bricolage Grotesque for headings, Instrument Sans for body,
/// IBM Plex Mono for codes (ticket codes, prices, small labels).
class T {
  static TextStyle display(double size, {Color color = C.ink, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: weight, color: color, height: 1.05, letterSpacing: -0.4);

  static TextStyle body(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.instrumentSans(fontSize: size, fontWeight: weight, color: color, height: 1.35);

  static TextStyle mono(double size, {Color color = C.ink, FontWeight weight = FontWeight.w600, double spacing = 0}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);

  /// Small all-caps label ("AI & TECH", "LIVE NOW").
  static TextStyle eyebrow({Color color = C.muted}) => mono(12, color: color, weight: FontWeight.w600, spacing: 1.6);
}

ThemeData buildTheme() {
  // Instrument Sans everywhere by default (GoogleFonts registers and downloads it)
  final base = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: C.accent,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.instrumentSans().fontFamily,
  );
  final radius = BorderRadius.circular(14);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: T.display(22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: C.danger),
      ),
      labelStyle: T.body(15, color: C.muted),
      hintStyle: T.body(15, color: C.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: T.body(17, weight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.ink,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: C.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: T.body(16, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.accent,
        textStyle: T.body(15, weight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => T.body(
          12,
          weight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? C.accent : C.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.accent : C.muted)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.ink,
      contentTextStyle: T.body(15, color: C.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    dividerTheme: const DividerThemeData(color: C.line, thickness: 1, space: 1),
  );
}
