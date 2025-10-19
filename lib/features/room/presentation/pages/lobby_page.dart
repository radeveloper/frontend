import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/session/session.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../poker_socket.dart';
import '../../../auth/presentation/pages/nickname_page.dart';
import '../controllers/voting_panel_controller.dart';
import '../widgets/participant_chip.dart';
import '../widgets/reveal_screen.dart';
import '../widgets/transfer_ownership_dialog.dart';
import '../widgets/voting_panel.dart';
import '../widgets/voting_status_widget.dart';

class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> with WidgetsBindingObserver {
  bool _leaving = false;
  String? _myVoteValue;
  String? _code;
  Map<String, dynamic>? _room; // {id, code, name, deckType}
  List<Map<String, dynamic>> _participants = const [];
  Map<String, dynamic>? _round; // {id, status, storyId}
  List<Map<String, dynamic>> _votes = const [];
  num? _average;
  String? _selfPid;
  bool _loading = true;
  late VotingPanelController _votingPanelController;

  @override
  void initState() {
    super.initState();
    _votingPanelController = VotingPanelController();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    _votingPanelController.dispose();
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
    // Örn. lobby_page.dart, _attachSocket() içinde:
    s.on('disconnect', (reason) {
      if (!mounted) return;

      // Sunucunun kapattığı bağlantı: 'io server disconnect' (Socket.IO standard)
      final r = (reason?.toString() ?? '').toLowerCase();
      final serverClosed = r.contains('io server disconnect');

      // Zaten odadaydık ve bağlantı server tarafından kapandıysa güvenli çıkış yap
      if (serverClosed && (_code != null && _code!.isNotEmpty)) {
        Session.I.clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NicknamePage()),
              (route) => false,
        );
      }
    });

    s.on('kicked', (data) {
      if (!mounted) return;
      // Kullanıcıya bilgilendirme
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You were removed from the room')),
      );
      // Session verilerini sıfırla
      Session.I.clear();
      // NicknamePage’e yönlendir (tüm sayfaları kapatarak)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NicknamePage()),
            (route) => false,
      );
      // WebSocket bağlantısını da kapat (artık odadayız)
      try {
        (PokerSocket.I as dynamic).disconnect?.call();
      } catch (_) {}
    });


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
      try {
        s.off(ev);

      } catch (_) {}
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

  bool get _canStartVoting =>
      _isOwner && _status == 'pending' && _activeParticipantCount >= 2;

  // ---------------------- Presence touch ----------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final code = _code;
    if (code == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      try {
        (PokerSocket.I as dynamic)
            .emit
            ?.call('presence_touch', <String, dynamic>{'code': code});
      } catch (_) {}
    }
    super.didChangeAppLifecycleState(state);
  }

  String? _tryGetRoomCode() {
    try {
      final s = PokerSocket.I as dynamic;
      final v = s.currentCode ??
          s.code ??
          s.joinedCode ??
          s.roomCode ??
          s.currentRoomCode;
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
    // payload, backend'in buildState* çıktısı
    if (payload is! Map) return;

    final room = (payload['room'] ?? const {}) as Map;
    final participants = (payload['participants'] ?? const []) as List;
    final round = (payload['round']) as Map?;
    final votes = (payload['votes'] ?? const []) as List;
    final avg = payload['average'];
    final newStatus = (round?['status'] as String?) ?? 'pending';

    // Check if current user has voted
    bool userHasVoted = false;
    if (_selfPid != null) {
      final me = participants.firstWhere(
        (p) => p['id'] == _selfPid,
        orElse: () => const {},
      );
      userHasVoted = me['hasVoted'] == true;
    }

    setState(() {
      _room = room.cast<String, dynamic>();
      _participants =
          participants.map((e) => (e as Map).cast<String, dynamic>()).toList();
      _round = round?.cast<String, dynamic>();
      _votes = votes.map((e) => (e as Map).cast<String, dynamic>()).toList();
      _average = (avg is num) ? avg : null;
      _code = (_room?['code'] as String?) ?? _code;

      // Seçim yönetimi - update voting panel controller
      if (newStatus == 'pending') {
        _myVoteValue = null; // yeni tura hazırlık
      } else if (newStatus == 'voting') {
        // Eğer server "hasVoted=false" diyorsa seçim temizlenebilir:
        if (!userHasVoted) _myVoteValue = null;
      } else if (newStatus == 'revealed') {
        // İstersen reveal'da kendi kartını _myVoteValue olarak set edebilirsin:
        if (_selfPid != null) {
          final my = _votes.firstWhere(
                (v) => v['participantId'] == _selfPid,
            orElse: () => const {},
          );
          final v = (my['value'] as String?)?.trim();
          if (v != null && v.isNotEmpty) _myVoteValue = v;
        }
      }
    });

    // Update voting panel controller with new status
    _votingPanelController.updateRoundStatus(newStatus, userHasVoted: userHasVoted);

    _ensureSelfPid();
  }

  void _ensureSelfPid() {
    if (_selfPid != null && _selfPid!.isNotEmpty) return;

    final sid = Session.I.participantId;
    if (sid != null && sid.isNotEmpty) {
      final meById = _participants.firstWhere(
            (p) => (p['id']?.toString() ?? '') == sid,
        orElse: () => const {},
      );
      final foundId = meById['id']?.toString();
      if (foundId != null && foundId.isNotEmpty) {
        setState(() => _selfPid = foundId);
        return;
      }
    }

    final dn = Session.I.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      final meByName = _participants.lastWhere(
            (p) => (p['displayName']?.toString() ?? '') == dn,
        orElse: () => const {},
      );
      final foundId = meByName['id']?.toString();
      if (foundId != null && foundId.isNotEmpty) {
        setState(() => _selfPid = foundId);
      }
    }
  }

  // ---------------------- Actions ----------------------

  bool get _isOwner {
    // Öncelikle kendimizi tespit edebildiğimiz en güvenilir id
    final myPid = (_selfPid?.trim().isNotEmpty ?? false)
        ? _selfPid
        : ((Session.I.participantId?.trim().isNotEmpty ?? false)
        ? Session.I.participantId
        : null);

    if (myPid != null && myPid.isNotEmpty) {
      return _participants.any((p) {
        final pid = p['id']?.toString() ?? '';
        final isOwner = p['isOwner'] == true;
        return pid == myPid && isOwner;
      });
    }

    // Son çare: displayName ile eşle
    final dn = Session.I.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      return _participants.any((p) {
        final name = p['displayName']?.toString() ?? '';
        final isOwner = p['isOwner'] == true;
        return name == dn && isOwner;
      });
    }

    return false;
  }

  // _participants listesi normalize edilmiş (alive) katılımcılar: { id, displayName, isOwner, ... }
  List<Map<String, dynamic>> get _eligibleTransferees {
    return _participants
        .where((p) => p['isOwner'] != true) // owner dışındakiler
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  String get _status => (_round?['status'] as String?) ?? 'pending';

  Future<void> _touchPresenceOnce() async {
    final code = _code;
    if (code == null) return;
    try {
      (PokerSocket.I as dynamic)
          .emit
          ?.call('presence_touch', <String, dynamic>{'code': code});
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
    (PokerSocket.I as dynamic)
        .emit
        ?.call('reveal', <String, dynamic>{'code': code});
  }

  Future<void> _reset() async {
    await _touchPresenceOnce();
    final code = _code;
    if (code == null) return;
    (PokerSocket.I as dynamic)
        .emit
        ?.call('reset', <String, dynamic>{'code': code});
  }

  Future<void> _vote(String value) async {
    await _touchPresenceOnce();
    final code = _code;
    if (code == null) return;

    // Mark the vote in voting panel controller
    _votingPanelController.markAsVoted(value);

    setState(() => _myVoteValue = value); // optimistic feedback
    (PokerSocket.I as dynamic).emit?.call('vote', <String, dynamic>{
      'code': code,
      'value': value,
    });
  }

  Future<String?> _pickTransfereeDialog(BuildContext context) async {
    final options = _eligibleTransferees;
    if (options.isEmpty) return null;

    return TransferOwnershipDialog.show(context, options);
  }

  // ---------------------- Leave flow (geri butonu) ----------------------

  Future _handleBack() async {
    if (_leaving) return;

    final code = _code;
    if (code == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    // Basit onay
    // ...
    final confirm = await AppDialog.confirm(
      context,
      title: 'Leave room?',
      message: 'You will be removed from the room.',
      confirmText: 'Leave',
      cancelText: 'Stay',
    );

    if (!mounted) return;

    if (confirm != true) return;

    // Eğer owner’san ve devralacak katılımcı varsa, seçim iste
    String? transferToPid;
    if (_isOwner) {
      final transferees = _eligibleTransferees;
      if (transferees.isNotEmpty) {
        // Tek kişi varsa otomatik seç
        if (transferees.length == 1) {
          transferToPid = transferees.first['id']?.toString();
        } else {
          // ⛳️ LINT FIX: async gap sonrası context kullanımı guard edildi
          final result = await _pickTransfereeDialog(context); // <-- ASENKRON BOŞLUK BURADA
          if (!mounted) return; // <-- BU SATIR ÇÖZÜM
          transferToPid = result;
          if (transferToPid == null) {
            // Kullanıcı vazgeçti
            return;
          }
        }

      }
      // Not: transferees boşsa (owner tek kişi ise) transfer gerekmeyecek.
    }

    await _leaveGracefully(code, transferToParticipantId: transferToPid);
  }

  /// Tek sorumlu fonksiyon: önce graceful leave (ack bekler), sonra dialog kapatır,
  /// sayfadan çıkar ve en sonda socket’i kapatır.
  Future _leaveGracefully(String code,
      {String? transferToParticipantId}) async {
    if (_leaving) return;
    setState(() => _leaving = true);

    try {
      final socket = PokerSocket.I as dynamic;
      final hasLeaveRoom = (socket.leaveRoom is Function);

      if (hasLeaveRoom) {
        try {
          await socket.leaveRoom(code,
              transferToParticipantId: transferToParticipantId);
        } catch (_) {
          await _leaveWithAckFallback(code,
              transferToParticipantId: transferToParticipantId);
        }
      } else {
        await _leaveWithAckFallback(code,
            transferToParticipantId: transferToParticipantId);
      }

      try {
        await _postLeave(code,
            transferToParticipantId: transferToParticipantId);
      } catch (_) {}

      _dismissAnyDialog();
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      try {
        socket.disconnect?.call();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  /// Fallback: 'leave_room' emit edip 'left_ack' bekler (maks 6 sn).
  Future _leaveWithAckFallback(String code,
      {String? transferToParticipantId}) async {
    final s = PokerSocket.I as dynamic;

    final completer = Completer<void>();
    void offAll() {
      try {
        s.off?.call('left_ack');
      } catch (_) {}
      try {
        s.off?.call('error');
      } catch (_) {}
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

    // İsteği gönder —>> transferToParticipantId'yi ilet
    try {
      s.emit?.call('leave_room', {
        'code': code,
        if (transferToParticipantId != null)
          'transferToParticipantId': transferToParticipantId,
      });
    } catch (_) {}

    await completer.future.timeout(const Duration(seconds: 6), onTimeout: () {
      if (!completer.isCompleted) completer.complete();
      offAll();
    });
  }

  Future<void> _handleKick(String participantId) async {
    // Onay dialogu
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Remove participant?',
      message: 'Are you sure you want to remove this participant from the room?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
    );
    if (confirmed != true) return;
    final code = _code;
    if (code == null) return;
    try {
      await _touchPresenceOnce();
      PokerSocket.I.kickParticipant(participantId);
    } catch (e) {
      // Hata mesajı
    }
  }


  Future _postLeave(String code, {String? transferToParticipantId}) async {
    final body = <String, dynamic>{};
    if (transferToParticipantId != null) {
      body['transferToParticipantId'] = transferToParticipantId;
    }
    await ApiClient().post('/api/v1/rooms/$code/leave', body);
  }

  void _dismissAnyDialog() {
    // async gap'lerden sonra çağrılma ihtimaline karşı guard eklendi
    if (!mounted) return;

    // Eğer dialog hâlâ açıksa kapat
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}
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
      child: Stack(
        children: [
          AppScaffold(
            title: _room?['name']?.toString() ?? 'Lobby',
            roomCode: _room?['code']?.toString() ?? _code, // sağ üstte kopyalanabilir
            body: _loading ? const _Loading() : _buildBody(context),
            currentIndex: 0,
            onNavSelected: (_) {},
            showNav: true,
          ),
          // Voting Panel Overlay
          AnimatedBuilder(
            animation: _votingPanelController,
            builder: (context, child) {
              return VotingPanel(
                deckType: (_room?['deckType'] ?? 'fibonacci').toString(),
                onVote: _vote,
                selectedValue: _votingPanelController.selectedValue,
                isOpen: _votingPanelController.isOpen,
                onClose: () => _votingPanelController.closePanel(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final status = _status;
    // Show full-screen reveal experience when status is revealed
    if (status == 'revealed') {
      return RevealScreen(
        average: _average,
        votes: _votes,
        participants: _participants,
        onReset: _isOwner ? _reset : null,
        isOwner: _isOwner,
      );
    }


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Katılımcılar
              AppSectionHeader(title: 'Participants (${_participants.length})'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _participants.map((p) {
                  final pid = p['id']?.toString() ?? '';
                  final isOwner = p['isOwner'] == true;
                  final showKick = _isOwner && pid.isNotEmpty && pid != _selfPid && !isOwner;

                  return ParticipantChip(
                    participant: p,
                    status: status,
                    votes: _votes,
                    showKick: showKick,
                    onKick: showKick ? () => _handleKick(pid) : null,
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
              if (_isOwner &&
                  _status == 'pending' &&
                  _activeParticipantCount < 2)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Start için en az 2 aktif katılımcı gerekli',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
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
                // Voting status widget
                AnimatedBuilder(
                  animation: _votingPanelController,
                  builder: (context, child) => VotingStatusWidget(
                    controller: _votingPanelController,
                    myVoteValue: _myVoteValue,
                  ),
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
