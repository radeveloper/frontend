import 'package:flutter/foundation.dart';

import '../../data/room_service.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/room_state.dart';
import '../../domain/models/round.dart';
import '../../domain/models/vote.dart';

class LobbyProvider extends ChangeNotifier {
  final RoomService _roomService;

  RoomState? _state;
  String? _selfParticipantId;
  String? _myVoteValue;
  bool _loading = true;
  bool _leaving = false;

  LobbyProvider({required RoomService roomService}) : _roomService = roomService;

  // Getters
  bool get loading => _loading;
  bool get leaving => _leaving;
  String? get myVoteValue => _myVoteValue;
  RoomState? get state => _state;
  String? get roomCode => _state?.room.code;

  bool get canStartVoting {
    if (_state == null) return false;
    return isOwner &&
           _state!.round.status == RoundStatus.pending &&
           getActiveParticipants().length >= 2;
  }

  bool get isOwner {
    if (_state == null || _selfParticipantId == null) return false;
    return _state!.participants.any((p) =>
      p.id == _selfParticipantId && p.isOwner);
  }

  List<Participant> getActiveParticipants() {
    if (_state == null) return [];
    const grace = Duration(seconds: 30);
    return _state!.participants
        .where((p) => p.isActive(grace))
        .toList();
  }

  // Initialize
  Future<void> initialize(String? code) async {
    if (code == null) return;

    try {
      _state = await _roomService.fetchRoom(code);
      _setupSocketListeners();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _roomService.attachListeners(
      onRoomState: (state) {
        _state = state;
        _updateMyVoteValue();
        notifyListeners();
      },
      onParticipantSelf: (pid) {
        _selfParticipantId = pid;
        notifyListeners();
      },
      onError: (msg) {
        debugPrint('Socket error: $msg');
      },
      onLeftAck: () {
        _roomService.disconnect();
      },
    );
  }

  void _updateMyVoteValue() {
    if (_state == null || _selfParticipantId == null) return;

    if (_state!.round.status == RoundStatus.pending) {
      _myVoteValue = null;
    } else if (_state!.round.status == RoundStatus.voting) {
      final me = _state!.participants
          .firstWhere((p) => p.id == _selfParticipantId,
                      orElse: () => const Participant(id: '', displayName: ''));
      if (!me.hasVoted) _myVoteValue = null;
    } else if (_state!.round.status == RoundStatus.revealed) {
      final myVote = _state!.votes
          .firstWhere((v) => v.participantId == _selfParticipantId,
                      orElse: () => const Vote(participantId: '', value: ''));
      if (myVote.value.isNotEmpty) _myVoteValue = myVote.value;
    }
  }

  // Actions
  Future<void> vote(String value) async {
    if (_state == null) return;
    _myVoteValue = value; // Optimistic update
    notifyListeners();
    _roomService.emitVote(_state!.room.code, value);
  }

  Future<void> startVoting() async {
    if (_state == null) return;
    _roomService.emitStartVoting(_state!.room.code);
  }

  Future<void> reveal() async {
    if (_state == null) return;
    _roomService.emitReveal(_state!.room.code);
  }

  Future<void> reset() async {
    if (_state == null) return;
    _roomService.emitReset(_state!.room.code);
  }

  Future<void> leaveRoom({String? transferToParticipantId}) async {
    if (_state == null || _leaving) return;

    _leaving = true;
    notifyListeners();

    try {
      await _roomService.leaveRoom(
        _state!.room.code,
        transferToParticipantId: transferToParticipantId,
      );
      await _roomService.postLeave(
        _state!.room.code,
        transferToParticipantId: transferToParticipantId,
      );
    } finally {
      _leaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomService.detachListeners();
    super.dispose();
  }
}
