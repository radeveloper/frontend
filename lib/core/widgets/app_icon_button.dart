import 'package:flutter/material.dart';

enum AppIconButtonSize { sm, md, lg }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppIconButtonSize.md,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final String? tooltip;

  double get _side => switch (size) {
    AppIconButtonSize.sm => 32,
    AppIconButtonSize.md => 40,
    AppIconButtonSize.lg => 48,
  };

  double get _icon => switch (size) {
    AppIconButtonSize.sm => 18,
    AppIconButtonSize.md => 22,
    AppIconButtonSize.lg => 24,
  };

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: _side,
      height: _side,
      child: IconButton(
        onPressed: onPressed,
        iconSize: _icon,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}
