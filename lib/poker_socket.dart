// lib/poker_socket.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'core/config/env.dart';
import 'core/session/session.dart';

typedef Json = Map<String, dynamic>;

class PokerSocket {
  PokerSocket._();
  static final PokerSocket I = PokerSocket._();

  IO.Socket? _socket;
  String? _code;

  String? selfParticipantId;

  bool get connected => _socket?.connected == true;
  String? get socketId => _socket?.id;

  // UI katmanı için callback'ler
  void Function(Json)? onRoomState;
  void Function(Json)? onVotingStarted;
  void Function(Json)? onRevealed;
  void Function(Json)? onResetDone;

  void Function(String participantId)? onParticipantSelf;
  void Function(String message)? onErrorEvent;
  void Function()? onVoteAck;

  // joinRoom beklemesi için tek-seferlik tamamlayıcı
  Completer<Json>? _pendingRoomState;

  /// WS bağlantısını kurar.
  /// - [hostBase]: 'http://192.168.1.23:3000' gibi (buradan ws URL türetilir)
  /// - [wsBase]: 'ws://192.168.1.23:3000/poker' gibi (doğrudan ws)
  /// - [jwt]: Token override (boşsa Session.I.token kullanılır)
  void connect({String? hostBase, String? wsBase, String? jwt}) {
    final token = (jwt ?? Session.I.token) ?? '';
    if (token.isEmpty) {
      throw Exception('No JWT token in Session');
    }

    disconnect(); // eski soketi kapat

    final url = _buildWsUrl(hostBase: hostBase, wsBase: wsBase);

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .enableForceNew()
          .disableAutoConnect()
          .build(),
    );

    // Temel event'ler
    _socket!.onConnect((_) => _log('connected ${_socket!.id}'));
    _socket!.onConnectError((e) => _log('connect_error $e'));
    _socket!.onError((e) => _log('error $e'));
    _socket!.onDisconnect((_) => _log('disconnected'));

    // ✅ Server genel error eventi (UI'da gösterebilmek için)
    _socket!.on('error', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      final msg = _toJson(raw)['message']?.toString() ?? raw.toString();
      onErrorEvent?.call(msg);
      _log('ws error: $raw');
    });

    // ✅ Oy atıldı ack
    _socket!.on('vote_cast_ack', (a, [b, c, d]) {
      onVoteAck?.call();
    });

    // ✅ Kendi participant id'mizi alalım
    _socket!.on('participant_self', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      final id = _toJson(raw)['participantId']?.toString();
      if (id != null && id.isNotEmpty) {
        selfParticipantId = id;
        onParticipantSelf?.call(id);
      }
    });

    // Server -> Client event'leri (çok argüman gelebilir)
    _socket!.on('room_state', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      final json = _toJson(raw);
      onRoomState?.call(json);
      // joinRoom bekliyorsa tamamla
      _pendingRoomState?.complete(json);
      _pendingRoomState = null;
    });
    _socket!.on('voting_started', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      onVotingStarted?.call(_toJson(raw));
    });
    _socket!.on('revealed', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      onRevealed?.call(_toJson(raw));
    });
    _socket!.on('reset_done', (a, [b, c, d]) {
      final raw = _firstMap(a, b, c, d) ?? a;
      onResetDone?.call(_toJson(raw));
    });

    _socket!.connect();
  }

  void disconnect() {
    try {
      _pendingRoomState = null;
      _socket?.off('room_state');
      _socket?.off('voting_started');
      _socket?.off('revealed');
      _socket?.off('reset_done');
      _socket?.disconnect();
      (_socket as dynamic)?.close?.call();
      (_socket as dynamic)?.dispose?.call();
    } catch (_) {
      // swallow
    } finally {
      _socket = null;
    }
  }

  /// Odaya katıl; ilk 'room_state' geldiğinde Future tamamlanır.
  Future<Json> joinRoom(String code, {Duration timeout = const Duration(seconds: 8)}) {
    _code = code;
    final s = _ensureConnected();

    // varsa önceki beklemeyi iptal et
    _pendingRoomState = Completer<Json>();

    // Join isteğini gönder (ack bağımlılığı yok)
    s.emit('join_room', {'code': code});

    return _pendingRoomState!.future.timeout(timeout, onTimeout: () {
      _pendingRoomState = null;
      throw Exception('join_room timeout');
    });
  }

  /// Owner aksiyonları
  void startVoting() => _emit('start_voting', {'code': _code});
  void reveal()      => _emit('reveal',       {'code': _code});
  void reset()       => _emit('reset',        {'code': _code});

  /// Katılımcı aksiyonu
  void vote(String value) => _emit('vote', {'code': _code, 'value': value});

  // ---- Helpers ----

  IO.Socket _ensureConnected() {
    final s = _socket;
    if (s == null || s.disconnected) {
      throw Exception('Socket not connected');
    }
    return s;
  }

  void _emit(String event, [dynamic data]) {
    final s = _ensureConnected();
    s.emit(event, data);
  }

  Json _toJson(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {'ok': data};
  }

  Map? _firstMap(dynamic a, [dynamic b, dynamic c, dynamic d]) {
    if (a is Map) return a;
    if (b is Map) return b;
    if (c is Map) return c;
    if (d is Map) return d;
    return null;
  }

  String _buildWsUrl({String? hostBase, String? wsBase}) {
    if (wsBase != null && wsBase.isNotEmpty) {
      return _ensurePokerPath(wsBase);
    }
    final base = (hostBase?.isNotEmpty ?? false) ? hostBase! : Env.api;
    if (base.startsWith('ws://') || base.startsWith('wss://')) {
      return _ensurePokerPath(base);
    }
    final httpish = (base.startsWith('http://') || base.startsWith('https://')) ? base : 'http://$base';
    final ws = httpish.replaceFirst(RegExp(r'^http'), 'ws');
    return _ensurePokerPath(ws);
  }

  String _ensurePokerPath(String wsUrl) {
    if (wsUrl.endsWith('/poker')) return wsUrl;
    if (wsUrl.endsWith('/')) return '${wsUrl}poker';
    return '$wsUrl/poker';
  }

  void _log(Object o) => print('[SOCKET] $o');
}
