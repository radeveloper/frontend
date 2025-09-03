import 'package:flutter/material.dart';

@immutable
class AppColors {
  static const bg = Color(0xFF0F141C);
  static const surface = Color(0xFF0F141C);
  static const surfaceCard = Color(0xFF18202A);
  static const primary = Color(0xFFE81932);
  static const neutral700 = Color(0xFF3A414A);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA8B0BC);
  static const divider = Color(0xFF2A323C);
}

class AppRadius {
  static const button = 28.0; // StadiumBorder için yüksek yarıçap
  static const card = 24.0;
  static const field = 14.0;
}

class AppSpacing {
  static const xxs = 4.0;
  static const xs  = 8.0;
  static const s   = 12.0;
  static const m   = 16.0;
  static const l   = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppShadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.45),
      blurRadius: 18,
      offset: const Offset(0, 12),
    ),
  ];
}


enum AppButtonSize { large, medium, small }

extension AppButtonSizeSpec on AppButtonSize {
  double get height => switch (this) {
    AppButtonSize.large => 56,
    AppButtonSize.medium => 48,
    AppButtonSize.small => 40,
  };

  double get fontSize => switch (this) {
    AppButtonSize.large => 18,
    AppButtonSize.medium => 16,
    AppButtonSize.small => 14,
  };

  EdgeInsetsGeometry get padding => const EdgeInsets.symmetric(horizontal: 24);
}
