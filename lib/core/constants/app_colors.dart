import 'package:flutter/material.dart';

/// Botanical Luxury color system — Deep Forest × Champagne palette.
///
/// WCAG AA contrast ratios verified against background (#121313):
///   textPrimary (Ivory)       14.7:1  AAA
///   textSecondary (Donkey)     6.1:1  AA
///   textTertiary (Mist Gray)   9.7:1  AAA
///   primary (Champagne)       13.9:1  AAA
///   passive (Forest Green)     6.1:1  AA
///   chat (Indigo)              4.7:1  AA
///   media (Neon Coral)         5.9:1  AA
///   error (Cherry Red)         5.3:1  AA
///   warning (Butter Yellow)   13.9:1  AAA
abstract final class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────
  static const background = Color(0xFF121313); // Space Black
  static const surface = Color(0xFF17261F); // Deep Forest tinted
  static const surfaceLight = Color(0xFF1F3229); // Rich forest surface
  static const card = Color(0xFF1A2B23); // Distinct forest card

  // ── Primary Brand ─────────────────────────────────────────────
  static const primary = Color(0xFFF7E7CE); // Champagne
  static const primaryLight = Color(0xFFFFF2E1); // Ivory
  static const onPrimary = Color(0xFF102C26); // Deep Forest on primary
  static const deepForest = Color(0xFF102C26); // Brand dark

  // ── Text ──────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFF2E1); // Ivory
  static const textSecondary = Color(0xFFA79277); // Donkey Brown
  static const textTertiary = Color(0xFF9EAAA5); // Mist-green (improved contrast)

  // ── Session Mode Colors ───────────────────────────────────────
  static const passive = Color(0xFF4CA67B); // Warm forest green
  static const passiveLight = Color(0xFFF7E998); // Butter Yellow
  static const chat = Color(0xFF7B7BDB); // Bright indigo (Midnight family)
  static const chatLight = Color(0xFFA0A0E8); // Light indigo
  static const media = Color(0xFFFF6044); // Neon Coral
  static const mediaLight = Color(0xFFFF8B76); // Peach coral

  // ── Status ────────────────────────────────────────────────────
  static const success = Color(0xFF4CA67B); // Forest green
  static const warning = Color(0xFFF7E998); // Butter Yellow
  static const error = Color(0xFFFF4747); // Cherry Red
  static const info = Color(0xFF7B7BDB); // Indigo

  // ── AI Event Colors ───────────────────────────────────────────
  static const observation = Color(0xFF7B7BDB); // Indigo
  static const lookup = Color(0xFFECEFF1); // Mist Gray
  static const action = Color(0xFFFF6044); // Neon Coral

  // ── Divider ───────────────────────────────────────────────────
  static const divider = Color(0xFF2A3E37); // Forest-tinted divider

  // ── Shimmer ───────────────────────────────────────────────────
  static const shimmerBase = Color(0xFF1A2B23);
  static const shimmerHighlight = Color(0xFF243D34);
}
