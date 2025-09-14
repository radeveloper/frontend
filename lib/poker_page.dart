// lib/poker_socket.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'core/config/env.dart';
import 'core/session/session.dart';
import 'package:logging/logging.dart';

typedef Json = Map<String, dynamic>;

class PokerSocket {
  static final _logger = Logger('PokerSocket');
  PokerSocket._();
  static final PokerSocket I = PokerSocket._();

  io.Socket? _socket;
  String? _code;

  bool get connected => _socket?.connected == true;
  String? get socketId => _socket?.id;

  // UI katmanının set edeceği callback'ler
  void Function(Json)? onRoomState;
  void Function(Json)? onVotingStarted;
  void Function(Json)? onRevealed;
  void Function(Json)? onResetDone;

  /// WS bağlantısını kurar.
  /// - [hostBase]: Örn: 'http://192.168.1.23:3000' (buradan ws URL otomatik türetilir)
  /// - [wsBase]: Örn: 'ws://192.168.1.23:3000/poker' (doğrudan WS adresi)
  /// - [jwt]: Token override (vermezsen Session.I.token kullanılır)
  void connect({String? hostBase, String? wsBase, String? jwt}) {
    final token = (jwt ?? Session.I.token) ?? '';
    if (token.isEmpty) {
      throw Exception('No JWT token in Session');
    }

    // Eski bağlantıyı kapat
    disconnect();

    final url = _buildWsUrl(hostBase: hostBase, wsBase: wsBase);

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
      // Sunucu hem handshake.auth.token hem de Authorization header'ını kabul ediyor.
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

    // Server -> Client event'leri
    _socket!.on('room_state', (d) => onRoomState?.call(_toJson(d)));
    _socket!.on('voting_started', (d) => onVotingStarted?.call(_toJson(d)));
    _socket!.on('revealed', (d) => onRevealed?.call(_toJson(d)));
    _socket!.on('reset_done', (d) => onResetDone?.call(_toJson(d)));

    _socket!.connect();
  }

  void disconnect() {
    try {
      _socket?.off('room_state');
      _socket?.off('voting_started');
      _socket?.off('revealed');
      _socket?.off('reset_done');
      _socket?.disconnect();
      // Bazı sürümlerde close() yok; varsa deneyelim
      // ignore: avoid_dynamic_calls
      (_socket as dynamic)?.close?.call();

    } catch (_) {
      // swallow
    } finally {
      _socket = null;
    }
  }

  /// Odaya katıl; ilk 'room_state' geldiğinde Future tamamlanır.
  /// Sürüm farklarından etkilenmeyen, güvenli yöntem.
  Future<Json> joinRoom(String code, {Duration timeout = const Duration(seconds: 6)}) {
    _code = code;
    final s = _ensureConnected();

    final completer = Completer<Json>();

    // İlk room_state'i yakalayıp Future'ı tamamla
    late void Function(dynamic) handler;
    handler = (dynamic data) {
      _socket?.off('room_state', handler);
      if (!completer.isCompleted) {
        completer.complete(_toJson(data));
      }
    };

    // Emit'ten önce handler'ı tak (yarış durumunu önle)
    _socket?.on('room_state', handler);

    // Join isteğini gönder
    s.emit('join_room', {'code': code});

    // Timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        _socket?.off('room_state', handler);
        completer.completeError(Exception('join_room timeout'));
      }
    });

    return completer.future;
  }

  /// Owner aksiyonları
  void startVoting() => _emit('start_voting', {'code': _code});
  void reveal()      => _emit('reveal',       {'code': _code});
  void reset()       => _emit('reset',        {'code': _code});

  /// Katılımcı aksiyonu
  void vote(String value) => _emit('vote', {'code': _code, 'value': value});

  // ---- Helpers ----

  io.Socket _ensureConnected() {
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
      // anahtarları String'e normalize et
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    // primitive payload ise sar
    return {'ok': data};
  }

  String _buildWsUrl({String? hostBase, String? wsBase}) {
    // Öncelik wsBase
    if (wsBase != null && wsBase.isNotEmpty) {
      return _ensurePokerPath(wsBase);
    }

    // hostBase verilmişse onu kullan, yoksa Env.api (http tabanlı)
    final base = (hostBase?.isNotEmpty ?? false) ? hostBase! : Env.api;

    if (base.startsWith('ws://') || base.startsWith('wss://')) {
      return _ensurePokerPath(base);
    }

    // http/https → ws/wss çevir
    final httpish = (base.startsWith('http://') || base.startsWith('https://'))
        ? base
        : 'http://$base'; // protokol yoksa http varsay
    final ws = httpish.replaceFirst(RegExp(r'^http'), 'ws');
    return _ensurePokerPath(ws);
  }

  String _ensurePokerPath(String wsUrl) {
    // '/poker' yoksa ekle
    if (wsUrl.endsWith('/poker')) return wsUrl;
    if (wsUrl.endsWith('/')) return '${wsUrl}poker';
    return '$wsUrl/poker';
  }

  void _log(Object o) => _logger.info('[SOCKET] $o');
}
