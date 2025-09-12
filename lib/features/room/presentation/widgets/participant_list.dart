import 'package:flutter/material.dart';
import '../../domain/models/participant.dart';

class ParticipantList extends StatelessWidget {
  final List<Participant> participants;
  final String roundStatus;

  const ParticipantList({
    super.key,
    required this.participants,
    required this.roundStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Participants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: participants.map((p) {
            final voted = p.hasVoted && roundStatus == 'voting';
            return Chip(
              avatar: Icon(
                voted ? Icons.check_circle : Icons.person,
                size: 18,
                color: voted ? Colors.green : null,
              ),
              label: Text(
                '${p.displayName}${p.isOwner ? ' (owner)' : ''}',
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
