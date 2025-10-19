import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, gradient }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.expand = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool expand;
  final AppButtonVariant variant;
  final AppButtonSize size;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _height => switch (widget.size) {
    AppButtonSize.sm => 40,
    AppButtonSize.md => 52,
    AppButtonSize.lg => 60,
  };

  double get _hPadding => switch (widget.size) {
    AppButtonSize.sm => 16,
    AppButtonSize.md => 24,
    AppButtonSize.lg => 32,
  };

  double get _iconSize => switch (widget.size) {
    AppButtonSize.sm => 18,
    AppButtonSize.md => 20,
    AppButtonSize.lg => 22,
  };

  double get _fontSize => switch (widget.size) {
    AppButtonSize.sm => 14,
    AppButtonSize.md => 16,
    AppButtonSize.lg => 18,
  };

  double get _gap => 8;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    Widget buttonContent = _buildContent();

    Widget button;

    switch (widget.variant) {
      case AppButtonVariant.gradient:
        button = _buildGradientButton(buttonContent, isDisabled);
        break;
      case AppButtonVariant.primary:
        button = _buildPrimaryButton(buttonContent, isDisabled);
        break;
      case AppButtonVariant.secondary:
        button = _buildSecondaryButton(buttonContent, isDisabled);
        break;
      case AppButtonVariant.ghost:
        button = _buildGhostButton(buttonContent, isDisabled);
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final textStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: widget.variant == AppButtonVariant.ghost
        ? AppColors.primary
        : Colors.white,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          SizedBox(width: _iconSize, height: _iconSize, child: widget.leading),
          SizedBox(width: _gap),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: textStyle,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.trailing != null) ...[
          SizedBox(width: _gap),
          SizedBox(width: _iconSize, height: _iconSize, child: widget.trailing),
        ],
      ],
    );
  }

  Widget _buildGradientButton(Widget content, bool isDisabled) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.neutral600 : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: isDisabled ? null : (_isHovered ? AppShadow.glow : AppShadow.soft),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(Widget content, bool isDisabled) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.neutral600 : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: isDisabled ? null : (_isHovered ? AppShadow.glow : AppShadow.soft),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(Widget content, bool isDisabled) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: isDisabled ? AppColors.neutral600 : AppColors.primary,
          width: 2,
        ),
        boxShadow: _isHovered ? AppShadow.soft : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildGhostButton(Widget content, bool isDisabled) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _hPadding),
      decoration: BoxDecoration(
        color: _isHovered ? AppColors.glassOverlay : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(child: content),
        ),
      ),
    );
  }
}
