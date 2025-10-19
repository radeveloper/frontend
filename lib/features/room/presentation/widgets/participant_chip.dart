import 'package:flutter/material.dart';

class ParticipantChip extends StatelessWidget {
  final Map<String, dynamic> participant;
  final String status;
  final List<Map<String, dynamic>> votes;
  final bool showKick;
  final VoidCallback? onKick;

  const ParticipantChip({
    super.key,
    required this.participant,
    required this.status,
    required this.votes,
    this.showKick = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final voted = participant['hasVoted'] == true && status == 'voting';
    final isOwner = participant['isOwner'] == true;
    final pid = participant['id']?.toString() ?? '';

    String? userVote;
    if (status == 'revealed') {
      final vote = votes.firstWhere(
        (v) => v['participantId'] == pid,
        orElse: () => const {},
      );
      userVote = vote['value']?.toString();
    }

    return Chip(
      avatar: status == 'revealed' && userVote != null
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  userVote,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : Icon(
              voted ? Icons.check_circle : Icons.person,
              size: 18,
              color: voted ? Colors.green : Colors.white,
            ),
      label: Text(
        '${participant['displayName']}${isOwner ? ' (owner)' : ''}',
      ),
      onDeleted: showKick ? onKick : null,
      deleteIcon: showKick ? const Icon(Icons.close, size: 18) : null,
    );
  }
}

