import 'package:flutter/material.dart';

/// LabsVpn Design System Colors
/// Dark theme from hitvpn.html, Light theme from hitvpn_light.html
class MokyColors {
  MokyColors._();

  // ── DARK THEME ──
  static const darkBg = Color(0xFF121212);
  static const darkS1 = Color(0xFF1E1E1E);
  static const darkS2 = Color(0xFF2A2A2A);
  static const darkS3 = Color(0xFF333333);
  static const darkB1 = Color(0xFF2A2A2A);
  static const darkB2 = Color(0xFF3A3A3A);
  static const darkAccent = Color(0xFF4CAF50);
  static const darkText = Color(0xFFFFFFFF);
  static const darkT2 = Color(0xFFB0B0B0);
  static const darkT3 = Color(0xFF707070);
  static const darkGreen = Color(0xFF4CAF50);
  static const darkRed = Color(0xFFFF5F72);

  // ── LIGHT THEME ──
  static const lightBg = Color(0xFFF5F5F7);
  static const lightS1 = Color(0xFFFFFFFF);
  static const lightS2 = Color(0xFFF0F0F2);
  static const lightS3 = Color(0xFFE0E0E2);
  static const lightB1 = Color(0xFFE0E0E2);
  static const lightB2 = Color(0xFFD1D1D6);
  static const lightAccent = Color(0xFF4CAF50);
  static const lightText = Color(0xFF111827);
  static const lightT2 = Color(0xFF6B7280);
  static const lightT3 = Color(0xFF9CA3AF);
  static const lightGreen = Color(0xFF10B981);
  static const lightRed = Color(0xFFEF4444);

  // ── SHARED ──
  static const accentGradientStart = Color(0xFF5B8EFF);
  static const accentGradientEnd = Color(0xFF7AA3FF);
}

/// Extension to provide moky colors from BuildContext
class MokyThemeData {
  final Color bg;
  final Color s1;
  final Color s2;
  final Color s3;
  final Color b1;
  final Color b2;
  final Color accent;
  final Color text;
  final Color t2;
  final Color t3;
  final Color green;
  final Color red;
  final bool isDark;

  const MokyThemeData({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.b1,
    required this.b2,
    required this.accent,
    required this.text,
    required this.t2,
    required this.t3,
    required this.green,
    required this.red,
    required this.isDark,
  });

  static const dark = MokyThemeData(
    bg: MokyColors.darkBg,
    s1: MokyColors.darkS1,
    s2: MokyColors.darkS2,
    s3: MokyColors.darkS3,
    b1: MokyColors.darkB1,
    b2: MokyColors.darkB2,
    accent: MokyColors.darkAccent,
    text: MokyColors.darkText,
    t2: MokyColors.darkT2,
    t3: MokyColors.darkT3,
    green: MokyColors.darkGreen,
    red: MokyColors.darkRed,
    isDark: true,
  );

  static const light = MokyThemeData(
    bg: MokyColors.lightBg,
    s1: MokyColors.lightS1,
    s2: MokyColors.lightS2,
    s3: MokyColors.lightS3,
    b1: MokyColors.lightB1,
    b2: MokyColors.lightB2,
    accent: MokyColors.lightAccent,
    text: MokyColors.lightText,
    t2: MokyColors.lightT2,
    t3: MokyColors.lightT3,
    green: MokyColors.lightGreen,
    red: MokyColors.lightRed,
    isDark: false,
  );

  /// Get dim (10% opacity) variant of accent
  Color get accentDim => accent.withValues(alpha: 0.1);

  /// Get mid (22% opacity) variant of accent
  Color get accentMid => accent.withValues(alpha: 0.22);

  /// Get dim (10% opacity) variant of green
  Color get greenDim => green.withValues(alpha: 0.1);

  /// Get mid (22% opacity) variant of green
  Color get greenMid => green.withValues(alpha: 0.22);

  /// Get dim (10% opacity) variant of red
  Color get redDim => red.withValues(alpha: 0.1);

  static MokyThemeData of(BuildContext context) {
    final themeBrightness = Theme.of(context).brightness;
    if (themeBrightness == Brightness.dark) return dark;
    if (themeBrightness == Brightness.light) return light;
    // Fallback for desktop edge cases when Theme.of returns default
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    return platformBrightness == Brightness.dark ? dark : light;
  }
}
