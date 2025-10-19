import 'package:flutter/material.dart';

/// Voting panel that opens as a full-screen overlay
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
            color: Colors.black.withValues(alpha: 0.8),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Your Vote',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _closePanel,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Voting cards
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Always maintain at least 3 columns, but scale up for larger screens
                            int crossAxisCount;
                            double childAspectRatio;
                            double crossAxisSpacing;
                            double mainAxisSpacing;

                            if (constraints.maxWidth < 350) {
                              // Very small screens - still 3 columns with tighter spacing
                              crossAxisCount = 3;
                              childAspectRatio = 0.8;
                              crossAxisSpacing = 8;
                              mainAxisSpacing = 8;
                            } else if (constraints.maxWidth < 500) {
                              // Small screens - 3 columns with normal spacing
                              crossAxisCount = 3;
                              childAspectRatio = 0.7;
                              crossAxisSpacing = 12;
                              mainAxisSpacing = 12;
                            } else if (constraints.maxWidth < 700) {
                              // Medium screens - 4 columns
                              crossAxisCount = 4;
                              childAspectRatio = 0.7;
                              crossAxisSpacing = 14;
                              mainAxisSpacing = 14;
                            } else {
                              // Large screens - 5 columns for better use of space
                              crossAxisCount = 5;
                              childAspectRatio = 0.75;
                              crossAxisSpacing = 16;
                              mainAxisSpacing = 16;
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: crossAxisSpacing,
                                mainAxisSpacing: mainAxisSpacing,
                              ),
                              itemCount: _values.length,
                              itemBuilder: (context, index) {
                                final value = _values[index];
                                final isSelected = _localSelectedValue == value;

                                return GestureDetector(
                                  onTap: () => _selectValue(value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: constraints.maxWidth < 350 ? 24 : 28, // Responsive icon size
                                          ),
                                        SizedBox(height: constraints.maxWidth < 350 ? 4 : 8), // Responsive spacing
                                        Flexible( // Prevent text overflow
                                          child: Text(
                                            value,
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: isSelected ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: constraints.maxWidth < 350 ? 18 :
                                                        constraints.maxWidth < 500 ? 20 : 24, // Responsive font size
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Vote button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _localSelectedValue != null ? _submitVote : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Vote',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        );
      },
    );
  }
}
