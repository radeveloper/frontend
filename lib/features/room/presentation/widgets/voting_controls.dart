import 'package:flutter/material.dart';

class VotingControls extends StatelessWidget {
  final VoidCallback onReveal;
  final VoidCallback onReset;

  const VotingControls({
    super.key,
    required this.onReveal,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(
          onPressed: onReveal,
          child: const Text('Reveal'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onReset,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
