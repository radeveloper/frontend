import 'package:flutter/material.dart';

class VoteGrid extends StatelessWidget {
  const VoteGrid({
    super.key,
    required this.deck,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> deck;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cross = w >= 900 ? 8 : w >= 600 ? 6 : 4;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: deck.length,
              itemBuilder: (context, i) {
                final value = deck[i];
                return _VoteCard(
                  label: value,
                  onTap: () => onSelected(value),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      surfaceTintColor: cs.surfaceTint,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
