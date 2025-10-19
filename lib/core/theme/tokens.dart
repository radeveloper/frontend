import 'package:flutter/material.dart';

@immutable
class AppColors {
  // Modern dark background colors - Black tones
  static const bg = Color(0xFF0A0A0A);
  static const bgGradientStart = Color(0xFF000000);
  static const bgGradientEnd = Color(0xFF1A1A1A);

  // Surface colors - Dark grays
  static const surface = Color(0xFF121212);
  static const surfaceCard = Color(0xFF1C1C1C);
  static const surfaceElevated = Color(0xFF252525);

  // Primary red palette - Modern red tones
  static const primary = Color(0xFFFF0000); // Pure red
  static const primaryLight = Color(0xFFFF3333);
  static const primaryDark = Color(0xFFCC0000);

  // Accent colors - Red variations
  static const accent = Color(0xFFDC143C); // Crimson
  static const accentLight = Color(0xFFFF1744);
  static const success = Color(0xFF4CAF50); // Keep green for success
  static const warning = Color(0xFFFF9800); // Keep orange for warning
  static const danger = Color(0xFFFF0000);

  // Neutral grays - Black to white spectrum
  static const neutral900 = Color(0xFF0F0F0F);
  static const neutral800 = Color(0xFF1A1A1A);
  static const neutral700 = Color(0xFF2A2A2A);
  static const neutral600 = Color(0xFF3D3D3D);
  static const neutral500 = Color(0xFF525252);
  static const neutral400 = Color(0xFF6B6B6B);
  static const neutral300 = Color(0xFF999999);

  // Text colors - White tones
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFE0E0E0);
  static const textTertiary = Color(0xFFB0B0B0);

  // Divider & borders
  static const divider = Color(0xFF2A2A2A);
  static const border = Color(0xFF3D3D3D);

  // Glassmorphism overlay
  static const glassOverlay = Color(0x1AFFFFFF);
  static const glassStroke = Color(0x33FFFFFF);
}

class AppGradients {
  // Red to black gradient
  static const primary = LinearGradient(
    colors: [Color(0xFFFF0000), Color(0xFFCC0000), Color(0xFF8B0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark card gradient
  static const card = LinearGradient(
    colors: [Color(0xFF1C1C1C), Color(0xFF0F0F0F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Pure black background gradient
  static const background = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Red gradient for voting cards
  static const votingCard = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Selected card - Red gradient
  static const votingCardSelected = LinearGradient(
    colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // White to transparent for highlights
  static const whiteOverlay = LinearGradient(
    colors: [Color(0x1AFFFFFF), Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppRadius {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const button = 16.0;
  static const card = 20.0;
  static const lg = 24.0;
  static const xl = 28.0;
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
  static const xxxl = 64.0;
}

class AppShadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.6),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // Red glow for primary elements
  static List<BoxShadow> glow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Intense red glow for selected elements
  static List<BoxShadow> glowAccent = [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.5),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.7),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.1),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}
