// lib/features/room/presentation/pages/lobby_page.dart
import 'dart:async';
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

    // Fallback senaryosu için left_ack yakalayalım (leaveRoom yoksa kullanılacak)
    s.on('left_ack', (_) async {
      // Dialog açık kalırsa kapat
      _dismissAnyDialog();
      // Sayfadan çık
      if (mounted) Navigator.of(context).maybePop();
      // En sonda socket kapat
      try {
        (PokerSocket.I as dynamic).disconnect?.call();
      } catch (_) {}
    });
  }

  void _detachSocket() {
    final s = PokerSocket.I;
    for (final ev in ['room_state', 'participant_self', 'error', 'left_ack']) {
      try { s.off(ev); } catch (_) {}
    }
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

  Future<void> _touchPresenceOnce() async {
    final code = _code;
    if (code == null) return;
    try {
      (PokerSocket.I as dynamic).emit?.call('presence_touch', <String, dynamic>{'code': code});
    } catch (_) {}
  }

  Future<void> _startVoting() async {
    await _touchPresenceOnce();
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('start_voting', <String, dynamic>{
      'code': code,
      'storyId': null,
    });
  }

  Future<void> _reveal() async {
    await _touchPresenceOnce();
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('reveal', <String, dynamic>{'code': code});
  }

  Future<void> _reset() async {
    await _touchPresenceOnce();
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic).emit?.call('reset', <String, dynamic>{'code': code});
  }

  Future<void> _vote(String value) async {
    await _touchPresenceOnce();
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

    await _leaveGracefully(code);
  }

  /// Tek sorumlu fonksiyon: önce graceful leave (ack bekler), sonra dialog kapatır,
  /// sayfadan çıkar ve en sonda socket’i kapatır.
  Future<void> _leaveGracefully(String code) async {
    if (_leaving) return;
    setState(() => _leaving = true);

    try {
      // 1) Varsaysa PokerSocket.leaveRoom kullan
      final socket = PokerSocket.I as dynamic;
      final hasLeaveRoom = (socket.leaveRoom is Function);

      if (hasLeaveRoom) {
        try {
          await socket.leaveRoom(code); // left_ack ile tamamlanır
        } catch (_) {
          // düşerse fallback’e geç
          await _leaveWithAckFallback(code);
        }
      } else {
        // 2) Fallback: left_ack bekleyen emit + timeout
        await _leaveWithAckFallback(code);
      }

      // 3) (Emniyet kemeri) REST leave — backend zaten WS ile yaptı ama
      //    UI senkronizasyonu için fail-safe tutuyoruz (idempotent).
      try {
        await _postLeave(code);
      } catch (_) {
        // görmezden gel
      }

      // 4) Dialog’u kapat (açıksa)
      _dismissAnyDialog();

      // 5) Sayfadan çık
      if (mounted) {
        Navigator.of(context).maybePop();
      }

      // 6) En sonda socket kapat
      try {
        socket.disconnect?.call();
      } catch (_) {}

    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  /// Fallback: 'leave_room' emit edip 'left_ack' bekler (maks 6 sn).
  Future<void> _leaveWithAckFallback(String code) async {
    final s = PokerSocket.I as dynamic;

    final completer = Completer<void>();
    void offAll() {
      try { s.off?.call('left_ack'); } catch (_) {}
      try { s.off?.call('error'); } catch (_) {}
    }

    s.on?.call('left_ack', (_) {
      if (!completer.isCompleted) completer.complete();
      offAll();
    });

    s.on?.call('error', (data) {
      if (data is Map && data['code'] == 'LEAVE_FAILED') {
        if (!completer.isCompleted) {
          completer.completeError(Exception(data['message'] ?? 'leave failed'));
        }
        offAll();
      }
    });

    // İsteği gönder
    try { s.emit?.call('leave_room', <String, dynamic>{'code': code}); } catch (_) {}

    // Zaman aşımı: fail-closed (UI ilerlesin)
    await completer.future.timeout(const Duration(seconds: 6), onTimeout: () {
      if (!completer.isCompleted) completer.complete();
      offAll();
    });
  }

  void _dismissAnyDialog() {
    // Eğer dialog hâlâ açıksa kapat
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}
  }

  Future<void> _postLeave(String code, {String? transferToParticipantId}) async {
    final body = <String, dynamic>{};
    if (transferToParticipantId != null) {
      body['transferToParticipantId'] = transferToParticipantId;
    }
    await ApiClient().post('/api/v1/rooms/$code/leave', body);
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
