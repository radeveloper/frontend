import 'package:flutter/material.dart';
import '../controllers/voting_panel_controller.dart';

class VotingStatusWidget extends StatelessWidget {
  final VotingPanelController controller;
  final String? myVoteValue;

  const VotingStatusWidget({
    super.key,
    required this.controller,
    this.myVoteValue,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.canReopenPanel()) {
      return _buildReopenButton(context);
    } else if (controller.hasVoted) {
      return _buildVotedIndicator(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildReopenButton(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => controller.reopenPanel(),
            icon: const Icon(Icons.how_to_vote),
            label: const Text('Open Voting Panel'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to vote on this round',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVotedIndicator(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            'You have voted!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (myVoteValue != null) ...[
            const SizedBox(height: 4),
            Text(
              'Your vote: $myVoteValue',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}