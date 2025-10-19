import 'dart:math' as math;
import 'package:flutter/material.dart';

class RevealScreen extends StatefulWidget {
  final num? average;
  final List<Map<String, dynamic>> votes;
  final List<Map<String, dynamic>> participants;
  final VoidCallback? onReset;
  final bool isOwner;

  const RevealScreen({
    super.key,
    this.average,
    required this.votes,
    required this.participants,
    this.onReset,
    this.isOwner = false,
  });

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for average circle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotate animation for decorative elements
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Fade animation for stats
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Map<String, int> _getVoteDistribution() {
    final distribution = <String, int>{};
    for (final vote in widget.votes) {
      final value = vote['value']?.toString() ?? '?';
      distribution[value] = (distribution[value] ?? 0) + 1;
    }
    return distribution;
  }

  String _getMostCommonVote() {
    final distribution = _getVoteDistribution();
    if (distribution.isEmpty) return '?';

    return distribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int _getConsensusPercentage() {
    final distribution = _getVoteDistribution();
    if (distribution.isEmpty) return 0;

    final maxCount = distribution.values.reduce(math.max);
    return ((maxCount / widget.votes.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distribution = _getVoteDistribution();
    final mostCommon = _getMostCommonVote();
    final consensus = _getConsensusPercentage();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Votes Revealed!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Average Circle
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildAverageCircle(context),
                    ),
                    const SizedBox(height: 48),

                    // Stats Cards
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildStatsSection(
                        context,
                        distribution,
                        mostCommon,
                        consensus,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Vote Distribution
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildVoteDistribution(context, distribution),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Button
          if (widget.isOwner && widget.onReset != null)
            Container(
              padding: const EdgeInsets.all(24),
              child: FilledButton.tonalIcon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Start New Round'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAverageCircle(BuildContext context) {
    final theme = Theme.of(context);
    final avgValue = widget.average?.toStringAsFixed(1) ?? '?';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotating background decoration
        AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                      theme.colorScheme.tertiary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Main circle
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.secondaryContainer,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Average',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                avgValue,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
              ),
              Text(
                'story points',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    Map<String, int> distribution,
    String mostCommon,
    int consensus,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          context,
          icon: Icons.people,
          label: 'Total Votes',
          value: widget.votes.length.toString(),
          color: theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          icon: Icons.star,
          label: 'Most Common',
          value: mostCommon,
          color: theme.colorScheme.secondary,
        ),
        _buildStatCard(
          context,
          icon: Icons.pie_chart,
          label: 'Consensus',
          value: '$consensus%',
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVoteDistribution(
    BuildContext context,
    Map<String, int> distribution,
  ) {
    final theme = Theme.of(context);
    final sortedEntries = distribution.entries.toList()
      ..sort((a, b) {
        // Try to sort numerically first
        final aNum = num.tryParse(a.key);
        final bNum = num.tryParse(b.key);
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        }
        return a.key.compareTo(b.key);
      });


    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Vote Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...sortedEntries.map((entry) {
            final percentage = (entry.value / widget.votes.length);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${entry.value} vote${entry.value != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

