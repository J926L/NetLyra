import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NetLyra typography scale using Google Fonts for reliability.
class NetLyraTypography {
  NetLyraTypography._();

  // Primary Heading Font (Orbitron)
  static TextStyle get headingStyle => GoogleFonts.orbitron();
  
  // Primary Body Font (Noto Sans SC for CJK support)
  static TextStyle get bodyStyle => GoogleFonts.notoSansSc();
  
  // Technical Mono Font (Share Tech Mono for Industrial feel)
  static TextStyle get monoStyle => GoogleFonts.shareTechMono();

  // Heading styles
  static TextStyle get h1 => headingStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      );

  static TextStyle get h2 => headingStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      );

  static TextStyle get h3 => headingStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      );

  // Body styles
  static TextStyle get body => bodyStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => bodyStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // Mono styles
  static TextStyle get mono => monoStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get monoLarge => monoStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );
}

