import 'package:flutter/material.dart';

/// Runtime-resolved color scheme that adapts to light/dark mode.
///
/// Usage: `context.colors.background` instead of `AppColors.background`.
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  // ── Backgrounds ───────────────────────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color card;

  // ── Primary Brand ─────────────────────────────────────────────
  final Color primary;
  final Color primaryLight;
  final Color onPrimary;
  final Color deepForest;

  // ── Text ──────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Session Mode Colors ───────────────────────────────────────
  final Color passive;
  final Color passiveLight;
  final Color chat;
  final Color chatLight;
  final Color media;
  final Color mediaLight;

  // ── Status ────────────────────────────────────────────────────
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // ── AI Event Colors ───────────────────────────────────────────
  final Color observation;
  final Color lookup;
  final Color action;

  // ── Divider ───────────────────────────────────────────────────
  final Color divider;

  // ── Shimmer ───────────────────────────────────────────────────
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.card,
    required this.primary,
    required this.primaryLight,
    required this.onPrimary,
    required this.deepForest,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.passive,
    required this.passiveLight,
    required this.chat,
    required this.chatLight,
    required this.media,
    required this.mediaLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.observation,
    required this.lookup,
    required this.action,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  // ═══════════════════════════════════════════════════════════════
  // ── Dark theme (Space Black + Deep Forest surfaces) ──────────
  // ═══════════════════════════════════════════════════════════════

  static const dark = AppColorScheme(
    background: Color(0xFF121313),
    surface: Color(0xFF17261F),
    surfaceLight: Color(0xFF1F3229),
    card: Color(0xFF1A2B23),
    primary: Color(0xFFF7E7CE),
    primaryLight: Color(0xFFFFF2E1),
    onPrimary: Color(0xFF102C26),
    deepForest: Color(0xFF102C26),
    textPrimary: Color(0xFFFFF2E1),
    textSecondary: Color(0xFFA79277),
    textTertiary: Color(0xFF9EAAA5),
    passive: Color(0xFF4CA67B),
    passiveLight: Color(0xFFF7E998),
    chat: Color(0xFF7B7BDB),
    chatLight: Color(0xFFA0A0E8),
    media: Color(0xFFFF6044),
    mediaLight: Color(0xFFFF8B76),
    success: Color(0xFF4CA67B),
    warning: Color(0xFFF7E998),
    error: Color(0xFFFF4747),
    info: Color(0xFF7B7BDB),
    observation: Color(0xFF7B7BDB),
    lookup: Color(0xFFECEFF1),
    action: Color(0xFFFF6044),
    divider: Color(0xFF2A3E37),
    shimmerBase: Color(0xFF1A2B23),
    shimmerHighlight: Color(0xFF243D34),
  );

  // ═══════════════════════════════════════════════════════════════
  // ── Light theme (Ivory / Champagne backgrounds) ──────────────
  // ═══════════════════════════════════════════════════════════════

  static const light = AppColorScheme(
    background: Color(0xFFFAF6F1), // Warm ivory
    surface: Color(0xFFF3EDE5), // Champagne-tinted surface
    surfaceLight: Color(0xFFEBE3D9), // Deeper champagne
    card: Color(0xFFFFFFFF), // White cards
    primary: Color(0xFFA79277), // Donkey Brown as primary (warm)
    primaryLight: Color(0xFF8B7560), // Deeper brown
    onPrimary: Color(0xFFFFF2E1), // Ivory on brown buttons
    deepForest: Color(0xFFEBE3D9), // Light champagne for icon circles
    textPrimary: Color(0xFF2C2420), // Rich dark brown
    textSecondary: Color(0xFF6B5D4F), // Warm brown
    textTertiary: Color(0xFF9A8E82), // Muted brown
    passive: Color(0xFF3A8B62), // Forest green
    passiveLight: Color(0xFFD4C050), // Muted butter yellow
    chat: Color(0xFF5858B8), // Indigo
    chatLight: Color(0xFF7878D0),
    media: Color(0xFFD94A30), // Coral
    mediaLight: Color(0xFFFF6044),
    success: Color(0xFF3A8B62),
    warning: Color(0xFFC4A020), // Darker yellow for light bg
    error: Color(0xFFD93030), // Cherry red
    info: Color(0xFF5858B8),
    observation: Color(0xFF5858B8),
    lookup: Color(0xFF6B5D4F),
    action: Color(0xFFD94A30),
    divider: Color(0xFFE0D7CC), // Light champagne divider
    shimmerBase: Color(0xFFF3EDE5),
    shimmerHighlight: Color(0xFFE8DFD4),
  );

  @override
  AppColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? card,
    Color? primary,
    Color? primaryLight,
    Color? onPrimary,
    Color? deepForest,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? passive,
    Color? passiveLight,
    Color? chat,
    Color? chatLight,
    Color? media,
    Color? mediaLight,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? observation,
    Color? lookup,
    Color? action,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      onPrimary: onPrimary ?? this.onPrimary,
      deepForest: deepForest ?? this.deepForest,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      passive: passive ?? this.passive,
      passiveLight: passiveLight ?? this.passiveLight,
      chat: chat ?? this.chat,
      chatLight: chatLight ?? this.chatLight,
      media: media ?? this.media,
      mediaLight: mediaLight ?? this.mediaLight,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      observation: observation ?? this.observation,
      lookup: lookup ?? this.lookup,
      action: action ?? this.action,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      deepForest: Color.lerp(deepForest, other.deepForest, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      passive: Color.lerp(passive, other.passive, t)!,
      passiveLight: Color.lerp(passiveLight, other.passiveLight, t)!,
      chat: Color.lerp(chat, other.chat, t)!,
      chatLight: Color.lerp(chatLight, other.chatLight, t)!,
      media: Color.lerp(media, other.media, t)!,
      mediaLight: Color.lerp(mediaLight, other.mediaLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      observation: Color.lerp(observation, other.observation, t)!,
      lookup: Color.lerp(lookup, other.lookup, t)!,
      action: Color.lerp(action, other.action, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}

/// Convenience extension for accessing the color scheme from BuildContext.
extension AppColorSchemeX on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.dark;
}
