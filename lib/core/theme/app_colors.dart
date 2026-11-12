import 'package:flutter/material.dart';

/// App-wide color palette adhering to Material 3 design system.
/// Uses a professional deep teal / ocean seed color and standardized status colors.
class AppColors {
  AppColors._();

  // Brand seed color (Deep Teal / Ocean Blue)
  static const Color primarySeed = Color(0xFF0F766E);
  static const Color secondarySeed = Color(0xFF0284C7);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccess = Colors.white;
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Colors.white;
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Colors.white;
  static const Color onErrorContainer = Color(0xFF991B1B);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);
  static const Color onInfo = Colors.white;
  static const Color onInfoContainer = Color(0xFF1E40AF);
}
