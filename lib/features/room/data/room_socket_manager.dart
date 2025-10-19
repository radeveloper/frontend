import '../../../../poker_socket.dart';

class RoomSocketManager {
  final PokerSocket socket;
  final void Function(dynamic) onRoomState;
  final void Function(String) onParticipantSelf;
  final void Function(dynamic) onError;
  final void Function() onKicked;
  final void Function(String) onDisconnect;

  RoomSocketManager({
    required this.socket,
    required this.onRoomState,
    required this.onParticipantSelf,
    required this.onError,
    required this.onKicked,
    required this.onDisconnect,
  });

  void attach() {
    socket.on('room_state', onRoomState);
    socket.on('participant_self', (data) {
      final pid = (data is Map ? data['participantId'] : null)?.toString();
      if (pid != null && pid.isNotEmpty) onParticipantSelf(pid);
    });
    socket.on('error', onError);
    socket.on('kicked', (_) => onKicked());
    socket.on('disconnect', (reason) {
      final r = (reason?.toString() ?? '').toLowerCase();
      onDisconnect(r);
    });
  }

  void detach() {
    for (final event in [
      'room_state',
      'participant_self',
      'error',
      'kicked',
      'disconnect'
    ]) {
      try {
        socket.off(event);
      } catch (_) {}
    }
  }

  void emitVote(String code, String value) {
    (socket as dynamic).emit?.call('vote', {'code': code, 'value': value});
  }

  void emitStartVoting(String code) {
    (socket as dynamic).emit?.call('start_voting', {'code': code, 'storyId': null});
  }

  void emitReveal(String code) {
    (socket as dynamic).emit?.call('reveal', {'code': code});
  }

  void emitReset(String code) {
    (socket as dynamic).emit?.call('reset', {'code': code});
  }

  void touchPresence(String code) {
    try {
      (socket as dynamic).emit?.call('presence_touch', {'code': code});
    } catch (_) {}
  }
}

