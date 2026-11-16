import 'package:flutter/material.dart';

/// لوحة ألوان منظومة عزم المستوحاة من التصميم المعتمد
class AzmColors {
  AzmColors._();

  static const Color primary = Color(0xFF4338CA);
  static const Color primaryDeep = Color(0xFF312E81);
  static const Color primarySoft = Color(0xFFEEF2FF);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFD1FAE5);

  static const Color gold = Color(0xFFF59E0B);
  static const Color goldSoft = Color(0xFFFEF3C7);

  static const Color sky = Color(0xFF0EA5E9);
  static const Color rose = Color(0xFFEF4444);

  // Light surface palette
  static const Color lightBg = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextMuted = Color(0xFF6B7280);

  // Dark surface palette
  static const Color darkBg = Color(0xFF0B1020);
  static const Color darkSurface = Color(0xFF131A2E);
  static const Color darkBorder = Color(0xFF232C46);
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color darkTextMuted = Color(0xFF9CA3AF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF2563EB)],
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
