import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket.IO istemcisi (Flutter)
/// - Varsayılan reconnect davranışını kullanır (önerilen ve yeterli).
/// - `vote`/`reveal` için `storyId` opsiyoneldir (aktif story desteğine uyumlu).
/// - Bağlantıyı yenilerken dinleyici çakışmalarını önlemek için `disconnect()` temizlik yapar.

/// Socket.IO istemcisi (Flutter)
/// - Varsayılan reconnect davranışı (Socket.IO default) kullanılır.
/// - `vote`/`reveal` için `storyId` opsiyoneldir (aktif story desteğine uyumlu).
/// - Uygulama event’lerini (joined, story:revealed, story:reset, ...) UI katmanı dinler.
class PokerSocket {
  PokerSocket._();
  static final PokerSocket I = PokerSocket._();

  IO.Socket? _socket;

  /// Bağlan:
  /// iOS Simulator → http://127.0.0.1:3000
  /// Android Emulator → http://10.0.2.2:3000
  /// Gerçek cihaz → http://<bilgisayar-LAN-IP>:3000
  void connect({required String hostBase}) {
    final url = '$hostBase/poker';

    // Eski bağlantıyı temizle (dinleyiciler + soket)
    disconnect();

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket']) // mobilde doğrudan WS
          .disableAutoConnect()         // manuel connect kontrolü
          .setAuth({'token': '<dev-token-or-session-token>'})
          .build(),
    );

    // Bağlantı durumu logları
    _socket!.onConnect((_) => print('Socket connected: ${_socket!.id}'));
    _socket!.onConnectError((e) => print('WS connect_error: $e'));
    _socket!.onError((e) => print('WS error: $e'));       // transport hataları
    _socket!.onDisconnect((_) => print('WS disconnected'));

    // Debug: tüm eventleri görmek istersen aç (geliştirme sırasında faydalı)
    // _socket!.onAny((event, data) => print('SOCKET [$event]: $data'));
    _socket!.onAny((event, data) => print('SOCKET [$event]: $data'));
    _socket!.connect();
  }

  /// UI katmanının spesifik event'lere abone olması için yardımcı.
  void on(String event, void Function(dynamic) handler) => _socket?.on(event, handler);

  /// Belirli bir dinleyiciyi kaldır (handler verilmezse tüm dinleyiciler kaldırılır).
  void off(String event, [void Function(dynamic)? handler]) => _socket?.off(event, handler);

  /// Bağlı mı?
  bool get isConnected => _socket?.connected == true;

  /// Odaya katıl
  void join({required String code, required String name}) {
    _socket?.emit('join', {'code': code, 'name': name});
  }

  /// Oy ver — gateway aktif story kullandığı için storyId opsiyonel.
  void vote({
    required String code,
    String? storyId, // opsiyonel
    required String participantId,
    required String value,
  }) {
    final payload = <String, dynamic>{
      'code': code,
      'participantId': participantId,
      'value': value,
    };
    if (storyId != null) payload['storyId'] = storyId;
    _socket?.emit('vote', payload);
  }

  /// Açıkla — aktif story varsa storyId göndermene gerek yok.
  void reveal({required String code, String? storyId}) {
    final payload = <String, dynamic>{'code': code};
    if (storyId != null) payload['storyId'] = storyId;
    _socket?.emit('reveal', payload);
  }

  /// Tüm dinleyicileri temizleyip soketi kapat.
  void disconnect() {
    if (_socket == null) return;

    // Uygulama eventleri — UI tarafında abone olunanlar
    _socket!
      ..off('joined')
      ..off('participant:joined')
      ..off('vote:update')
      ..off('story:revealed')
      ..off('story:reset')
      ..off('reveal:accepted')
      ..off('error'); // gateway'ten gelebilecek app-level error

    // Bağlantı durumu eventleri
    _socket!
      ..off('connect')
      ..off('connect_error')
      ..off('error')
      ..off('disconnect');

    _socket!.dispose();
    _socket = null;
  }

  void reconnectWithAuth({required String token}) {
    if (_socket == null) return;
    final url = _socket!.io.uri; // mevcut url
    disconnect();
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token}) // 👈 WS handshake auth
          .build(),
    );
    _socket!.onConnect((_) => print('Socket connected: ${_socket!.id}'));
    _socket!.onConnectError((e) => print('WS connect_error: $e'));
    _socket!.onError((e) => print('WS error: $e'));
    _socket!.onDisconnect((_) => print('WS disconnected'));
    _socket!.onAny((event, data) => print('SOCKET [$event]: $data'));
    _socket!.connect();
  }

}

