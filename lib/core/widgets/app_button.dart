import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.leading,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(context);

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Text(label),
      ],
    );

    final btn = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: SizedBox(height: size.height, child: Center(child: child)),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  ButtonStyle _styleFor(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: size.fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: .2,
    );

    Color baseBg;
    Color baseFg = AppColors.textPrimary;

    switch (variant) {
      case AppButtonVariant.primary:
        baseBg = AppColors.primary;
        break;
      case AppButtonVariant.secondary:
        baseBg = AppColors.neutral700;
        break;
      case AppButtonVariant.text:
        baseBg = Colors.transparent;
        break;
    }

    Color resolveBg(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) return baseBg.withValues(alpha: 0.45);
      if (states.contains(WidgetState.pressed)) return Color.lerp(baseBg, Colors.black, .12)!;
      if (states.contains(WidgetState.hovered)) return Color.lerp(baseBg, Colors.white, .06)!;
      return baseBg;
    }

    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, size.height)),
      padding: WidgetStatePropertyAll(size.padding),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      elevation: const WidgetStatePropertyAll(12),
      shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.45),),
      backgroundColor: WidgetStateProperty.resolveWith(resolveBg),
      foregroundColor: WidgetStatePropertyAll(baseFg),
      textStyle: WidgetStatePropertyAll(textStyle),
      overlayColor: const WidgetStatePropertyAll(Colors.white12),
    );
  }
}
