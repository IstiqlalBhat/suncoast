import 'package:flutter/material.dart';

abstract final class AppColors {
  // Background
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF141420);
  static const surfaceLight = Color(0xFF1E1E2E);
  static const card = Color(0xFF1A1A2E);

  // Primary
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B83FF);

  // Text
  static const textPrimary = Color(0xFFE8E8F0);
  static const textSecondary = Color(0xFF9090A0);
  static const textTertiary = Color(0xFF606070);

  // Session Type Colors
  static const passive = Color(0xFF00C853);
  static const passiveLight = Color(0xFF69F0AE);
  static const chat = Color(0xFF448AFF);
  static const chatLight = Color(0xFF82B1FF);
  static const media = Color(0xFFFF6D00);
  static const mediaLight = Color(0xFFFFAB40);

  // Status
  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFFFAB00);
  static const error = Color(0xFFFF1744);
  static const info = Color(0xFF448AFF);

  // AI Event Colors
  static const observation = Color(0xFF7C4DFF);
  static const lookup = Color(0xFF00B0FF);
  static const action = Color(0xFFFF9100);

  // Divider
  static const divider = Color(0xFF2A2A3E);

  // Shimmer
  static const shimmerBase = Color(0xFF1A1A2E);
  static const shimmerHighlight = Color(0xFF2A2A3E);
}
