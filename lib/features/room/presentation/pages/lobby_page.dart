import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/session/session.dart';
import '../../../../poker_socket.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, this.initialRoomName});
  final String? initialRoomName;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  String _roomName = 'Room';
  String _status = 'pending'; // pending | voting | revealed
  List<_P> _participants = const [];
  double? _average;

  bool get _isOwner {
    final me = _participants.firstWhere(
          (p) => p.id == Session.I.participantId,
      orElse: () => _P.none(),
    );
    return me.isOwner;
  }

  @override
  void initState() {
    super.initState();
    _roomName = widget.initialRoomName ?? 'Room';

    PokerSocket.I.onRoomState = _onRoomState;
    PokerSocket.I.onVotingStarted = (d) {
      setState(() => _status = (d['round']?['status'] ?? 'voting').toString());
    };
    PokerSocket.I.onRevealed = (d) {
      final votes = (d['votes'] as List?) ?? const [];
      setState(() {
        _status = (d['round']?['status'] ?? 'revealed').toString();
        _average = (d['average'] is num) ? (d['average'] as num).toDouble() : null;
        _participants = _participants.map((p) {
          final v = votes.cast<Map>().firstWhere(
                (m) => m['participantId'] == p.id,
            orElse: () => const {},
          );
          final value = (v['value'] ?? '').toString();
          return p.copyWith(voteValue: value.isEmpty ? null : value);
        }).toList();
      });
    };
    PokerSocket.I.onResetDone = (_) {
      setState(() {
        _status = 'pending';
        _average = null;
        _participants = _participants.map((p) => p.copyWith(hasVoted: false, voteValue: null)).toList();
      });
    };
  }

  @override
  void dispose() {
    if (PokerSocket.I.onRoomState == _onRoomState) {
      PokerSocket.I.onRoomState = null;
    }
    PokerSocket.I.onVotingStarted = null;
    PokerSocket.I.onRevealed = null;
    PokerSocket.I.onResetDone = null;
    super.dispose();
  }

  void _onRoomState(Map<String, dynamic> s) {
    final room = (s['room'] as Map?) ?? const {};
    final participants = (s['participants'] as List?) ?? const [];
    final round = (s['round'] as Map?) ?? const {};
    final votes = (s['votes'] as List?) ?? const [];

    setState(() {
      _roomName = (room['name'] ?? _roomName).toString();
      _status = (round['status'] ?? _status).toString();

      _participants = participants.map((m) {
        final id = m['id']?.toString() ?? '';
        final name = m['displayName']?.toString() ?? 'Guest';
        final isOwner = m['isOwner'] == true;
        final hasVoted = m['hasVoted'] == true;
        String? voteValue;
        final v = votes.cast<Map>().firstWhere(
              (x) => x['participantId']?.toString() == id,
          orElse: () => const {},
        );
        final vv = v['value']?.toString();
        if (vv != null && vv.isNotEmpty) voteValue = vv;
              return _P(id: id, name: name, isOwner: isOwner, hasVoted: hasVoted, voteValue: voteValue);
      }).toList();

      if (s['average'] is num) _average = (s['average'] as num).toDouble();
    });
  }

  void _start() => PokerSocket.I.startVoting();
  void _reveal() => PokerSocket.I.reveal();
  void _reset() => PokerSocket.I.reset();
  void _vote(String v) => PokerSocket.I.vote(v);

  @override
  Widget build(BuildContext context) {
    final title = _roomName;
    final buttonLabel = switch (_status) {
      'pending' => 'Start Poker Round',
      'voting' => 'Reveal Votes',
      'revealed' => 'Start New Vote',
      _ => 'Start Poker Round'
    };
    final buttonAction = switch (_status) {
      'pending' => _start,
      'voting' => _reveal,
      'revealed' => _reset,
      _ => _start,
    };
    final buttonEnabled = _isOwner;

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: _participants.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, i) {
                final p = _participants[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.hasVoted ? Colors.green : AppColors.surfaceCard,
                    child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                  ),
                  title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(p.isOwner ? 'Host' : 'Participant',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  trailing: (_status == 'revealed' && p.voteValue != null)
                      ? _VoteChip(p.voteValue!)
                      : (p.hasVoted ? const Icon(Icons.check_circle, color: Colors.green) : null),
                  onTap: _status == 'voting' && p.id == Session.I.participantId
                      ? () => _openVoteSheet(context)
                      : null,
                );
              },
            ),
          ),

          if (_status == 'voting') _deckQuickBar(),

          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(boxShadow: AppShadow.soft),
            child: AppButton(
              label: buttonLabel,
              onPressed: buttonEnabled ? buttonAction : null,
              variant: AppButtonVariant.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (_status == 'revealed' && _average != null)
            Text('Average: ${_average!.toStringAsFixed(1)}',
                style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );

    return AppScaffold(
      title: title,
      body: body,
      currentIndex: 0,
      onNavSelected: (_) {},
      showNav: true,
    );
  }

  Widget _deckQuickBar() {
    const deck = ['1','2','3','5','8','13','21','?'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final v in deck)
            SizedBox(
              width: 64, height: 44,
              child: AppButton(
                label: v,
                onPressed: () => _vote(v),
                variant: AppButtonVariant.secondary,
              ),
            ),
        ],
      ),
    );
  }

  void _openVoteSheet(BuildContext context) {
    const deck = ['1','2','3','5','8','13','21','?'];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: [
              for (final v in deck)
                SizedBox(
                  width: 80, height: 56,
                  child: AppButton(
                    label: v,
                    onPressed: () { Navigator.pop(context); _vote(v); },
                    variant: AppButtonVariant.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _P {
  final String id;
  final String name;
  final bool isOwner;
  final bool hasVoted;
  final String? voteValue;

  const _P({
    required this.id,
    required this.name,
    required this.isOwner,
    required this.hasVoted,
    this.voteValue,
  });

  factory _P.none() => const _P(id: '', name: '', isOwner: false, hasVoted: false);

  _P copyWith({bool? hasVoted, String? voteValue}) =>
      _P(id: id, name: name, isOwner: isOwner, hasVoted: hasVoted ?? this.hasVoted, voteValue: voteValue);
}

class _VoteChip extends StatelessWidget {
  const _VoteChip(this.value);
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}
