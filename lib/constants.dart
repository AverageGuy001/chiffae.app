import 'package:flutter/material.dart';

/// Chifaae brand color palette
class AppColors {
  AppColors._(); // prevent instantiation

  /// Primary brand color – Emerald Green
  static const Color primary = Color(0xFF046307);

  /// Accent color
  static const Color accent = Color(0xFF0B8F18);

  /// Background – Mint White
  static const Color background = Color(0xFFF9FBF9);

  /// Surface cards
  static const Color surface = Color(0xFFFFFFFF);

  /// On-primary text / icons (white)
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// On-background / body text
  static const Color onBackground = Color(0xFF102312);

  /// Subtle muted text
  static const Color muted = Color(0xFF5B6D5E);

  // ─── Role-specific colors ──────────────────────────────────────────────

  /// Emerald Green – Pharmacist vibe
  static const Color pharmacistGreen = Color(0xFF046307);

  /// Hospital Blue – Generalist vibe
  static const Color generalistBlue = Color(0xFF1A5F9E);

  /// Teal – Specialist/Dentist vibe
  static const Color specialistTeal = Color(0xFF0D7377);
}
