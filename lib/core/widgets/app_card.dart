import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool withShadow;
  final bool withGlassmorphism;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.onTap,
    this.withShadow = false,
    this.withGlassmorphism = true,
    this.gradient,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_elevationAnimation.value * 0.5),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: widget.withShadow
                  ? (_isHovered ? AppShadow.medium : AppShadow.card)
                  : null,
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.glassStroke,
                width: 1.5,
              ),
            ),
            child: widget.withGlassmorphism
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card - 2),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.glassOverlay,
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: widget.child,
                      ),
                    ),
                  )
                : widget.child,
          ),
        );
      },
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: widget.onTap == null
          ? content
          : GestureDetector(
              onTap: widget.onTap,
              child: content,
            ),
    );
  }
}
