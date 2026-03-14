import 'package:flutter/material.dart';
import 'app_color_scheme.dart';

abstract final class AppGradients {
  static LinearGradient primaryGradient(AppColorScheme c) => LinearGradient(
    colors: [c.primary, c.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient passiveGradient(AppColorScheme c) => LinearGradient(
    colors: [c.passive, c.passiveLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient chatGradient(AppColorScheme c) => LinearGradient(
    colors: [c.chat, c.chatLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient mediaGradient(AppColorScheme c) => LinearGradient(
    colors: [c.media, c.mediaLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient(AppColorScheme c) => LinearGradient(
    colors: [
      c.background,
      c.deepForest.withValues(alpha: 0.6),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient cardGradient(AppColorScheme c) => LinearGradient(
    colors: [
      c.surfaceLight,
      c.surface,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient sessionGradient(Color color, AppColorScheme c) {
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.12),
        c.background,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
