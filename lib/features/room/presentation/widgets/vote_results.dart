import 'package:flutter/material.dart';
import '../../domain/models/vote.dart';

class VoteResults extends StatelessWidget {
  final List<Vote> votes;
  final num? average;
  final VoidCallback? onReset;
  final bool showResetButton;

  const VoteResults({
    super.key,
    required this.votes,
    this.average,
    this.onReset,
    this.showResetButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (average != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('Average: $average'),
                  avatar: const Icon(Icons.analytics),
                ),
              ),
            if (showResetButton && onReset != null)
              OutlinedButton(
                onPressed: onReset,
                child: const Text('Start new round'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: votes.map((v) => Chip(
            label: Text('${v.participantId}: ${v.value}'),
          )).toList(),
        ),
      ],
    );
  }
}
