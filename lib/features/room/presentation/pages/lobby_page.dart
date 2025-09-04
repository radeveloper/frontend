import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Represents the various states of the lobby.
///
/// * [LobbyStatus.beforeVoting] – The session has not yet started.
///   The host can see the number of participants and start the round.
/// * [LobbyStatus.voting] – Voting is underway; a green dot marks
///   participants who have submitted their estimates.
/// * [LobbyStatus.revealed] – Votes have been revealed; participant
///   avatars are replaced with their vote values and the average is shown.
enum LobbyStatus { beforeVoting, voting, revealed }

/// A simple model representing a participant in the poker room.
class Participant {
  final String name;
  final String? avatarUrl;
  final bool isHost;
  final bool hasVoted;
  final int? vote;

  const Participant({
    required this.name,
    this.avatarUrl,
    this.isHost = false,
    this.hasVoted = false,
    this.vote,
  });
}

/// The lobby page displays the participants around a circle and an action
/// button whose label changes based on the lobby status.
class LobbyPage extends StatefulWidget {
  final String roomName;
  final List<Participant> participants;
  final int maxParticipants;
  final LobbyStatus status;

  const LobbyPage({
    super.key,
    required this.roomName,
    required this.participants,
    required this.maxParticipants,
    this.status = LobbyStatus.beforeVoting,
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Determine the title and button text based on the current status.
    final String stageTitle = switch (widget.status) {
      LobbyStatus.beforeVoting =>
      'Participants (${widget.participants.length}/${widget.maxParticipants})',
      LobbyStatus.voting => 'Waiting for votes...',
      LobbyStatus.revealed => 'Votes Revealed',
    };

    final String buttonLabel = switch (widget.status) {
      LobbyStatus.beforeVoting => 'Start Poker Round',
      LobbyStatus.voting => 'Reveal Votes',
      LobbyStatus.revealed => 'Start New Vote',
    };

    double? average;
    if (widget.status == LobbyStatus.revealed) {
      final votes = widget.participants
          .map((p) => p.vote)
          .where((v) => v != null)
          .cast<int>()
          .toList();
      if (votes.isNotEmpty) {
        average = votes.reduce((a, b) => a + b) / votes.length;
      }
    }

    final body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Heading that shows participant count or voting status.
            Text(
              stageTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            // Circle of participants with interactive display.
            Expanded(
              child: _ParticipantCircle(
                participants: widget.participants,
                status: widget.status,
                average: average,
              ),
            ),
            const SizedBox(height: 24),
            // Primary CTA button with shadow. Actual behaviour should
            // be implemented in a real app (e.g. emit start/vote events).
            Container(
              decoration: BoxDecoration(boxShadow: AppShadow.soft),
              child: AppButton(
                label: buttonLabel,
                onPressed: () {
                  // TODO: Implement actual voting logic here.
                },
                variant: AppButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );

    return AppScaffold(
      title: widget.roomName,
      body: body,
      currentIndex: _navIndex,
      onNavSelected: (i) => setState(() => _navIndex = i),
    );
  }
}

/// Arranges participants evenly around a circle and optionally displays
/// an average in the center when votes have been revealed.
class _ParticipantCircle extends StatelessWidget {
  final List<Participant> participants;
  final LobbyStatus status;
  final double? average;

  const _ParticipantCircle({
    required this.participants,
    required this.status,
    this.average,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine a square area based on the smaller of width/height.
        final double size = math.min(constraints.maxWidth, constraints.maxHeight);
        const double avatarSize = 64.0;
        final double radius = (size / 2) - avatarSize - 12;
        final double centreX = constraints.maxWidth / 2;
        final double centreY = constraints.maxHeight / 2;
        final List<Widget> children = [];

        // Outer ring drawn as a faint circle.
        children.add(
          Positioned(
            left: centreX - radius,
            top: centreY - radius,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        );

        // Place each participant around the circle.
        final int count = participants.length;
        for (int i = 0; i < count; i++) {
          final double angle = (2 * math.pi * i / count) - (math.pi / 2);
          final double x = centreX + radius * math.cos(angle) - (avatarSize / 2);
          final double y = centreY + radius * math.sin(angle) - (avatarSize / 2);
          children.add(
            Positioned(
              left: x,
              top: y,
              child: _ParticipantItem(
                participant: participants[i],
                status: status,
                size: avatarSize,
              ),
            ),
          );
        }

        // If an average is provided, display it at the center.
        if (average != null) {
          children.add(
            Positioned(
              left: centreX - 60,
              top: centreY - 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Average',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    average!.toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }
}

/// Renders an individual participant's avatar, label, and voting state.
class _ParticipantItem extends StatelessWidget {
  final Participant participant;
  final LobbyStatus status;
  final double size;

  const _ParticipantItem({
    required this.participant,
    required this.status,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    if (status == LobbyStatus.revealed && participant.vote != null) {
      // After reveal, show the vote value inside a colored circle.
      avatarWidget = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.neutral700,
        ),
        child: Center(
          child: Text(
            participant.vote.toString(),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      );
    } else {
      // Otherwise display an avatar or fallback icon.
      avatarWidget = CircleAvatar(
        radius: size / 2,
        backgroundImage: participant.avatarUrl != null
            ? NetworkImage(participant.avatarUrl!)
            : null,
        child: participant.avatarUrl == null
            ? Icon(
          Icons.person,
          size: size / 2,
          color: AppColors.textSecondary,
        )
            : null,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            avatarWidget,
            // Show a small dot to indicate voting status during voting/reveal.
            if (status == LobbyStatus.voting || status == LobbyStatus.revealed)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: participant.hasVoted
                        ? Colors.greenAccent
                        : AppColors.divider,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          participant.name + (participant.isHost ? ' (Host)' : ''),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}