import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

/// Modern voting panel with black, white, and red theme
class VotingPanel extends StatefulWidget {
  const VotingPanel({
    super.key,
    required this.deckType,
    required this.onVote,
    this.selectedValue,
    this.isOpen = false,
    this.onClose,
  });

  final String deckType;
  final void Function(String value) onVote;
  final String? selectedValue;
  final bool isOpen;
  final VoidCallback? onClose;

  @override
  State<VotingPanel> createState() => _VotingPanelState();
}

class _VotingPanelState extends State<VotingPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  String? _localSelectedValue;

  @override
  void initState() {
    super.initState();
    _localSelectedValue = widget.selectedValue;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.isOpen) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(VotingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedValue != oldWidget.selectedValue) {
      _localSelectedValue = widget.selectedValue;
    }

    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          if (mounted) widget.onClose?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _values {
    switch (widget.deckType) {
      case 'tshirt':
        return const ['XS', 'S', 'M', 'L', 'XL', '?'];
      case 'fibonacci':
      default:
        return const ['0', '1/2', '1', '2', '3', '5', '8', '13', '?'];
    }
  }

  void _selectValue(String value) {
    setState(() {
      _localSelectedValue = value;
    });
  }

  void _submitVote() {
    if (_localSelectedValue != null) {
      widget.onVote(_localSelectedValue!);
      _animationController.reverse().then((_) {
        if (mounted) widget.onClose?.call();
      });
    }
  }

  void _closePanel() {
    _animationController.reverse().then((_) {
      if (mounted) widget.onClose?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    AppColors.bg.withValues(alpha: 0.98),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => AppGradients.primary.createShader(bounds),
                                  child: const Text(
                                    'Cast Your Vote',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Select your story point estimate',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: IconButton(
                                onPressed: _closePanel,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: Center(
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 700),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _values.length,
                                  itemBuilder: (context, index) {
                                    final value = _values[index];
                                    final isSelected = _localSelectedValue == value;
                                    return _VotingCard(
                                      value: value,
                                      isSelected: isSelected,
                                      onTap: () => _selectValue(value),
                                      delay: index * 50,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: AnimatedOpacity(
                            opacity: _localSelectedValue != null ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: _localSelectedValue != null ? AppGradients.primary : null,
                                color: _localSelectedValue == null ? AppColors.neutral600 : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _localSelectedValue != null ? AppShadow.glow : null,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _localSelectedValue != null ? _submitVote : null,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Submit Vote',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VotingCard extends StatefulWidget {
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final int delay;

  const _VotingCard({
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_VotingCard> createState() => _VotingCardState();
}

class _VotingCardState extends State<_VotingCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + widget.delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: MouseRegion(
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) => _hoverController.reverse(),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_elevationAnimation.value * 0.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()
                    ..setEntry(0, 0, _isPressed ? 0.95 : 1.0)
                    ..setEntry(1, 1, _isPressed ? 0.95 : 1.0)
                    ..setEntry(2, 2, _isPressed ? 0.95 : 1.0),
                  decoration: BoxDecoration(
                    gradient: widget.isSelected ? AppGradients.votingCardSelected : AppGradients.votingCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: widget.isSelected
                        ? AppShadow.glowAccent
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16 + _elevationAnimation.value,
                              offset: Offset(0, 8 + _elevationAnimation.value * 0.5),
                            ),
                          ],
                    border: Border.all(
                      color: widget.isSelected ? AppColors.primary : AppColors.border,
                      width: widget.isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.glassOverlay, Colors.transparent],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isSelected)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 32),
                                  );
                                },
                              ),
                            if (widget.isSelected) const SizedBox(height: 8),
                            Text(
                              widget.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.value.length > 2 ? 32 : 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: widget.isSelected
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
