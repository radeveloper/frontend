import 'package:flutter/material.dart';
import 'package:frontend/poker_socket.dart';
import 'package:frontend/features/room/domain/decks.dart';
import 'package:frontend/features/room/presentation/widgets/vote_grid.dart';
import '../../../../core/widgets/app_button.dart';

typedef Json = Map<String, dynamic>;

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, this.initialRoomName});
  final String? initialRoomName;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  Json? _state;                    // { room, participants, round, votes?, average? }
  String _roundStatus = 'pending'; // pending | voting | revealed
  bool _selfHasVoted = false;
  List<String> _deck = Decks.fibonacci;

  @override
  void initState() {
    super.initState();
    final ps = PokerSocket.I;
    ps.onRoomState = _onRoomState;
    ps.onErrorEvent = (msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $msg')));
    };
    ps.onVoteAck = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vote sent')));
    };
    ps.onParticipantSelf = (_) {/* self id geç gelebilir; bir sonraki state’te hesaplanır */};
  }

  @override
  void dispose() {
    final ps = PokerSocket.I;
    if (ps.onRoomState == _onRoomState) ps.onRoomState = null;
    ps.onErrorEvent = null;
    ps.onVoteAck = null;
    ps.onParticipantSelf = null;
    super.dispose();
  }

  // ---- Event handlers ----
  void _onRoomState(Json json) {
    final room = json['room'] as Map?;
    final parts = (json['participants'] as List?)?.cast<Map>() ?? const <Map>[];
    final round = json['round'] as Map?;
    final status = (round?['status'] ?? 'pending').toString();

    final deckType = room?['deckType']?.toString();
    final selfId = PokerSocket.I.selfParticipantId;

    bool selfVoted = false;
    if (selfId != null) {
      final me = parts.cast<Map<String, dynamic>?>().firstWhere(
            (p) => p?['id']?.toString() == selfId,
        orElse: () => null,
      );
      selfVoted = (me?['hasVoted'] == true);
    }

    setState(() {
      _state = json;
      _roundStatus = status;
      _selfHasVoted = selfVoted;
      _deck = Decks.resolve(deckType);
    });
  }

  // ---- Helpers ----
  bool get _isOwner {
    final parts = (_state?['participants'] as List?)?.cast<Map>() ?? const <Map>[];
    final selfId = PokerSocket.I.selfParticipantId;
    if (selfId == null) return false;
    final me = parts.firstWhere(
          (p) => (p['id']?.toString() == selfId),
      orElse: () => const {},
    );
    return me['isOwner'] == true;
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final participants = (_state?['participants'] as List?)?.cast<Map>() ?? const <Map>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Planning Poker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildParticipants(context, participants),
          const SizedBox(height: 16),
          VoteGrid(
            deck: _deck,
            enabled: _roundStatus == 'voting' && !_selfHasVoted,
            onSelected: (v) => PokerSocket.I.vote(v),
          ),
          const SizedBox(height: 24),
          if (_roundStatus == 'revealed') _buildResults(context),
          const SizedBox(height: 80), // CTA için altta nefes
        ],
      ),
      bottomNavigationBar: _buildPrimaryCta(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final room = _state?['room'] as Map?;
    final code = (room?['code'] ?? '').toString();
    final name = (room?['name'] ?? widget.initialRoomName ?? '').toString();

    return Row(
      children: [
        Expanded(
          child: Text(
            name.isEmpty && code.isEmpty ? 'Room' : [name, code].where((e) => e.isNotEmpty).join(' • '),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 8),
        _statusChip(),
      ],
    );
  }

  Widget _statusChip() {
    final color = switch (_roundStatus) {
      'voting' => Colors.orange,
      'revealed' => Colors.green,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(_roundStatus.toUpperCase()),
      backgroundColor: color.withValues(alpha: .15),
      side: BorderSide(color: color.withValues(alpha: .4)),
      labelStyle: TextStyle(color: color.shade700),
    );
  }

  Widget _buildParticipants(BuildContext context, List<Map> parts) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: parts.map((p) {
        final name = (p['displayName'] ?? 'Guest').toString();
        final voted = p['hasVoted'] == true;
        final isOwner = p['isOwner'] == true;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) const Icon(Icons.star, size: 16),
              if (isOwner) const SizedBox(width: 6),
              Text(name, style: style),
              const SizedBox(width: 8),
              Icon(
                voted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: voted ? Colors.green : Colors.black26,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResults(BuildContext context) {
    final avg = _state?['average'];
    final votes = (_state?['votes'] as List?)?.length ?? 0;
    if (avg == null) return const SizedBox.shrink();
    return Text('Average: $avg ($votes votes)', style: Theme.of(context).textTheme.titleLarge);
  }

  Widget? _buildPrimaryCta(BuildContext context) {
    if (!_isOwner) return const SizedBox.shrink();

    switch (_roundStatus) {
      case 'pending':
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton(
              label: 'Start Poker Round',
              variant: AppButtonVariant.primary,
              expand: true,
              onPressed: () => PokerSocket.I.startVoting(),
            ),
          ),
        );
      case 'voting':
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton(
              label: 'Reveal Votes',
              variant: AppButtonVariant.primary,
              expand: true,
              onPressed: () => PokerSocket.I.reveal(),
            ),
          ),
        );
      case 'revealed':
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton(
              label: 'Start New Vote',
              variant: AppButtonVariant.primary,
              expand: true,
              onPressed: () => PokerSocket.I.reset(),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
