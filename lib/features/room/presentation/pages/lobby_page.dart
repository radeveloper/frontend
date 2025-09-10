// lib/features/room/presentation/pages/lobby_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../poker_socket.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> with WidgetsBindingObserver {
  bool _leaving = false;

  String? _code;
  Map<String, dynamic>? _room; // {id, code, name, deckType}
  List<Map<String, dynamic>> _participants = const [];
  Map<String, dynamic>? _round; // {id, status, storyId}
  List<Map<String, dynamic>> _votes = const [];
  num? _average;
  String? _selfPid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachSocket();
    super.dispose();
  }

  // ---------------------- Bootstrap & Socket ----------------------

  Future<void> _bootstrap() async {
    _code = _tryGetRoomCode();
    _attachSocket();

    if (_code != null) {
      try {
        final s = await _fetchRoom(_code!);
        _consumeRoomStatePayload(s);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Load failed: $e')),
          );
        }
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _attachSocket() {
    final s = PokerSocket.I;
    s.on('room_state', (data) {
      if (!mounted) return;
      _consumeRoomStatePayload(data);
    });
    s.on('participant_self', (data) {
      if (!mounted) return;
      final pid = (data is Map ? data['participantId'] : null)?.toString();
      if (pid != null && pid.isNotEmpty) setState(() => _selfPid = pid);
    });
    s.on('error', (err) {
      if (!mounted) return;
      final msg = (err is Map && err['message'] != null)
          ? '[${err['code']}] ${err['message']}'
          : err.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  void _detachSocket() {
    final s = PokerSocket.I;
    try { s.off('room_state'); } catch (_) {}
    try { s.off('participant_self'); } catch (_) {}
    try { s.off('error'); } catch (_) {}
  }

  int get _activeParticipantCount {
    final now = DateTime.now();
    const grace = Duration(seconds: 30);

    return _participants.where((p) {
      // Ayrılanları çıkar
      final leftAt = p['leftAt'];
      if (leftAt != null) return false;

      // lastSeenAt kontrolü (ISO string veya DateTime olabilir)
      final raw = p['lastSeenAt'];
      DateTime? lastSeen;
      if (raw is String) {
        lastSeen = DateTime.tryParse(raw);
      } else if (raw is DateTime) {
        lastSeen = raw;
      }

      if (lastSeen != null && now.difference(lastSeen) > grace) {
        return false; // çevrimdışı say
      }

      return true; // aktif
    }).length;
  }

  bool get _canStartVoting => _isOwner && _status == 'pending' && _activeParticipantCount >= 2;

  // ---------------------- Presence touch ----------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final code = _code;
    if (code == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      try {
        (PokerSocket.I as dynamic).emit?.call('presence_touch', <String, dynamic>{'code': code});
      } catch (_) {}
    }
    super.didChangeAppLifecycleState(state);
  }

  String? _tryGetRoomCode() {
    try {
      final s = PokerSocket.I as dynamic;
      final v = s.currentCode ?? s.code ?? s.joinedCode ?? s.roomCode ?? s.currentRoomCode;
      if (v is String && v.trim().isNotEmpty) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------- REST helpers ----------------------

  Future<Map<String, dynamic>> _fetchRoom(String code) async {
    final dynamic raw = await ApiClient().get('/api/v1/rooms/$code');

    if (raw is Map<String, dynamic>) return raw;

    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    }

    try {
      final body = (raw as dynamic).body;
      if (body is String && body.isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}

    try {
      final data = (raw as dynamic).data;
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}

    throw StateError('Unexpected room payload: ${raw.runtimeType}');
  }

  // ---------------------- State consume ----------------------

  void _consumeRoomStatePayload(dynamic payload) {
    // payload, backend’in buildState* çıktısı
    if (payload is! Map) return;

    final room = (payload['room'] ?? const {}) as Map;
    final participants = (payload['participants'] ?? const []) as List;
    final round = (payload['round']) as Map?;
    final votes = (payload['votes'] ?? const []) as List;
    final avg = payload['average'];

    setState(() {
      _room = room.cast<String, dynamic>();
      _participants =
          participants.map((e) => (e as Map).cast<String, dynamic>()).toList();
      _round = round?.cast<String, dynamic>();
      _votes = votes.map((e) => (e as Map).cast<String, dynamic>()).toList();
      _average = (avg is num) ? avg : null;
      _code = (_room?['code'] as String?) ?? _code;
    });
  }

  // ---------------------- Actions ----------------------

  bool get _isOwner {
    if (_selfPid == null) return false;
    final me = _participants.firstWhere(
          (p) => p['id'] == _selfPid,
      orElse: () => const {},
    );
    return me['isOwner'] == true;
  }

  String get _status => (_round?['status'] as String?) ?? 'pending';

  Future<void> _startVoting() async {
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('start_voting', <String, dynamic>{
      'code': code,
      'storyId': null,
    });
  }

  Future<void> _reveal() async {
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('reveal', <String, dynamic>{'code': code});
  }

  Future<void> _reset() async {
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('reset', <String, dynamic>{'code': code});
  }

  Future<void> _vote(String value) async {
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('vote', <String, dynamic>{
      'code': code,
      'value': value,
    });
  }

  // ---------------------- Leave flow (geri butonu) ----------------------

  Future<void> _handleBack() async {
    if (_leaving) return;

    final code = _code;
    if (code == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    final confirm = await AppDialog.confirm(
      context,
      title: 'Leave room?',
      message: 'You will be removed from the room.',
      confirmText: 'Leave',
      cancelText: 'Stay',
    );
    if (confirm != true) return;

    setState(() => _leaving = true);

    var leaveSucceeded = false;
    try {
      await _postLeave(code);
      leaveSucceeded = true;
    } catch (e) {
      // owner transfer zorunluluğu olabilir
      final msg = e.toString().toLowerCase();
      final needsTransfer = msg.contains('owner must transfer');

      if (!needsTransfer) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Leave failed: $e')),
          );
        }
        setState(() => _leaving = false);
        return;
      }

      final transferee = await _pickTransferee(code);
      if (transferee == null) {
        setState(() => _leaving = false);
        return;
      }

      try {
        await _postLeave(code, transferToParticipantId: transferee);
        leaveSucceeded = true;
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Leave failed: $e2')),
          );
        }
        setState(() => _leaving = false);
        return;
      }
    } finally {
      if (leaveSucceeded) {
        try {
          (PokerSocket.I as dynamic).emit?.call('leave_room', <String, dynamic>{'code': code});
        } catch (_) {}
        try {
          (PokerSocket.I as dynamic)._socket?.close?.call();
        } catch (_) {}
        if (mounted) {
          setState(() => _leaving = false);
          Navigator.of(context).maybePop();
        }
      }
    }
  }

  Future<void> _postLeave(String code, {String? transferToParticipantId}) async {
    final body = <String, dynamic>{};
    if (transferToParticipantId != null) {
      body['transferToParticipantId'] = transferToParticipantId;
    }
    await ApiClient().post('/api/v1/rooms/$code/leave', body);
  }

  Future<String?> _pickTransferee(String code) async {
    final room = await _fetchRoom(code);
    if (!mounted) return null;

    final participants =
    (room['participants'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final candidates = participants
        .where((p) => (p['isOwner'] != true) && (p['leftAt'] == null))
        .toList();

    if (candidates.isEmpty) {
      if (!mounted) return null;
      await AppDialog.confirm(
        context,
        title: 'No transferee',
        message: 'No other participants to transfer ownership.',
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return null;
    }

    if (!mounted) return null;
    return await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AppSectionHeader(title: 'Transfer ownership to'),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = candidates[i];
                    return ListTile(
                      title: Text(p['displayName']?.toString() ?? 'Unknown'),
                      onTap: () => Navigator.of(ctx).pop(p['id']?.toString()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------------------- UI ----------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: AppScaffold(
        title: _room?['name']?.toString() ?? 'Lobby',
        body: _loading ? const _Loading() : _buildBody(context),
        currentIndex: 0,
        onNavSelected: (_) {},
        showNav: true,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final code = _code ?? _room?['code'];
    final status = _status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _room?['name']?.toString() ?? 'Room',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (code != null)
                    SelectableText(
                      'Code: $code',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Participants
              const AppSectionHeader(title: 'Participants'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _participants.map((p) {
                  final voted = p['hasVoted'] == true && status == 'voting';
                  final isOwner = p['isOwner'] == true;
                  return Chip(
                    avatar: Icon(
                      voted ? Icons.check_circle : Icons.person,
                      size: 18,
                      color: voted ? Colors.green : null,
                    ),
                    label: Text(
                      '${p['displayName']}${isOwner ? ' (owner)' : ''}',
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Round status
              AppSectionHeader(title: 'Status: ${status.toUpperCase()}'),
              const SizedBox(height: 8),

              if (status == 'pending' && _isOwner)
                FilledButton(
                  onPressed: _canStartVoting ? _startVoting : null,
                  child: const Text('Start voting'),
                ),
              if (_isOwner && _status == 'pending' && _activeParticipantCount < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Start için en az 2 aktif katılımcı gerekli',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              if (status == 'voting') ...[
                if (_isOwner)
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _reveal,
                        child: const Text('Reveal'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _VoteGrid(
                  deckType: (_room?['deckType'] ?? 'fibonacci').toString(),
                  onVote: _vote,
                ),
              ],

              if (status == 'revealed') ...[
                Row(
                  children: [
                    if (_average != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Chip(
                          label: Text('Average: $_average'),
                          avatar: const Icon(Icons.analytics),
                        ),
                      ),
                    if (_isOwner)
                      OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Start new round'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _votes
                      .map((v) => Chip(
                    label: Text('${v['participantId']}: ${v['value']}'),
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Basit oy kartları – tasarım bileşeninle değiştirebilirsin.
/// deckType: 'fibonacci' için klasik dizi.
class _VoteGrid extends StatelessWidget {
  const _VoteGrid({required this.deckType, required this.onVote});

  final String deckType;
  final void Function(String value) onVote;

  List<String> get _values {
    switch (deckType) {
      case 'tshirt':
        return const ['XS', 'S', 'M', 'L', 'XL', '?'];
      case 'fibonacci':
      default:
        return const ['0', '1/2', '1', '2', '3', '5', '8', '13', '?'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _values
          .map(
            (v) => OutlinedButton(
          onPressed: () => onVote(v),
          child: Text(v),
        ),
      )
          .toList(),
    );
  }
}
