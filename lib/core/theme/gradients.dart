import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class AppGradients {
  static const primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const passiveGradient = LinearGradient(
    colors: [AppColors.passive, AppColors.passiveLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const chatGradient = LinearGradient(
    colors: [AppColors.chat, AppColors.chatLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mediaGradient = LinearGradient(
    colors: [AppColors.media, AppColors.mediaLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [AppColors.background, AppColors.surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [
      Color(0xFF1A1A2E),
      Color(0xFF16162A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient sessionGradient(Color color) {
    return LinearGradient(
      colors: [
        color.withValues(alpha: 0.15),
        AppColors.background,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
