import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle word(BuildContext context) => GoogleFonts.sourceSerif4(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.inkBlack,
    height: 1.2,
  );

  static TextStyle wordSmall(BuildContext context) => GoogleFonts.sourceSerif4(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.inkBlack,
  );

  static TextStyle headline(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.inkBlack,
  );

  static TextStyle sectionLabel(BuildContext context) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF999999),
    letterSpacing: 0.5,
  );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.inkBlack,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    color: const Color(0xFF999999),
  );

  static TextStyle button(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle monoNumber(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.inkBlack,
  );

  static TextStyle monoNumberSmall(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    color: const Color(0xFF999999),
  );
}
