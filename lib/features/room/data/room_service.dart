import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../poker_socket.dart';
import '../domain/models/room_state.dart';
typedef RoomStateCallback = void Function(RoomState state);
typedef ParticipantIdCallback = void Function(String participantId);
typedef ErrorCallback = void Function(String message);

class RoomService {
  final _socket = PokerSocket.I;
  final _api = ApiClient();

  StreamSubscription? _stateSubscription;
  StreamSubscription? _selfSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _leftAckSubscription;

  void attachListeners({
    required RoomStateCallback onRoomState,
    required ParticipantIdCallback onParticipantSelf,
    required ErrorCallback onError,
    required VoidCallback onLeftAck,
  }) {
    _stateSubscription?.cancel();
    _selfSubscription?.cancel();
    _errorSubscription?.cancel();
    _leftAckSubscription?.cancel();

    _stateSubscription = _on('room_state', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final state = RoomState.fromJson(data);
          onRoomState(state);
        } catch (e) {
          onError('Failed to parse room state: $e');
        }
      }
    });

    _selfSubscription = _on('participant_self', (data) {
      if (data is Map && data['participantId'] != null) {
        onParticipantSelf(data['participantId'].toString());
      }
    });

    _errorSubscription = _on('error', (err) {
      final msg = (err is Map && err['message'] != null)
          ? '[${err['code']}] ${err['message']}'
          : err.toString();
      onError(msg);
    });

    _leftAckSubscription = _on('left_ack', (_) {
      onLeftAck();
    });
  }

  void detachListeners() {
    _stateSubscription?.cancel();
    _selfSubscription?.cancel();
    _errorSubscription?.cancel();
    _leftAckSubscription?.cancel();
  }

  StreamSubscription _on(String event, Function(dynamic) handler) {
    final controller = StreamController();
    _socket.on(event, (data) => controller.add(data));
    return controller.stream.listen(handler);
  }

  Future<RoomState> fetchRoom(String code) async {
    final response = await _api.get('/api/v1/rooms/$code');
    return RoomState.fromJson(response);
  }

  void emitVote(String code, String value) {
    _emit('vote', {'code': code, 'value': value});
  }

  void emitStartVoting(String code) {
    _emit('start_voting', {'code': code, 'storyId': null});
  }

  void emitReveal(String code) {
    _emit('reveal', {'code': code});
  }

  void emitReset(String code) {
    _emit('reset', {'code': code});
  }

  void emitPresenceTouch(String code) {
    _emit('presence_touch', {'code': code});
  }

  Future<void> leaveRoom(String code, {String? transferToParticipantId}) async {
    final socket = _socket as dynamic;

    if (socket.leaveRoom is Function) {
      try {
        await socket.leaveRoom(code, transferToParticipantId: transferToParticipantId);
        return;
      } catch (_) {
        // Fall through to fallback
      }
    }

    // Fallback implementation
    final completer = Completer<void>();

    final errorSub = _on('error', (data) {
      if (data is Map && data['code'] == 'LEAVE_FAILED') {
        completer.completeError(Exception(data['message'] ?? 'Leave failed'));
      }
    });

    final ackSub = _on('left_ack', (_) {
      if (!completer.isCompleted) completer.complete();
    });

    _emit('leave_room', {
      'code': code,
      if (transferToParticipantId != null)
        'transferToParticipantId': transferToParticipantId,
    });

    try {
      await completer.future.timeout(const Duration(seconds: 6));
    } finally {
      errorSub.cancel();
      ackSub.cancel();
    }
  }

  Future<void> postLeave(String code, {String? transferToParticipantId}) async {
    await _api.post(
      '/api/v1/rooms/$code/leave',
      {'transferToParticipantId': transferToParticipantId},
    );
  }

  void _emit(String event, Map<String, dynamic> data) {
    try {
      (_socket as dynamic).emit?.call(event, data);
    } catch (e) {
      debugPrint('Failed to emit $event: $e');
    }
  }

  void disconnect() {
    try {
      (_socket as dynamic).disconnect?.call();
    } catch (_) {}
  }
}
