import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Cross-platform environment config.
/// - Web'de `dart:io` KULLANMADAN çalışır.
/// - --dart-define ile override edilebilir:
///   flutter run -d chrome --dart-define=API_BASE=http://localhost:3000 --dart-define=WS_BASE=ws://localhost:3000/poker
class Env {
  // CLI'dan verilen override'lar:
  static const _apiDef = String.fromEnvironment('API_BASE');
  static const _wsDef  = String.fromEnvironment('WS_BASE');

  /// REST base URL (ör: http://localhost:3000)
  static String get api {
    if (_apiDef.isNotEmpty) return _apiDef;

    // WEB: varsayılan olarak local backend
    if (kIsWeb) {
      // Chrome aynı makinede çalıştığı için localhost:3000 iyi bir varsayılan.
      // Farklı host/port kullanıyorsan --dart-define ile geç.
      return 'http://localhost:3000';
    }

    // Mobil/Desktop: defaultTargetPlatform ile seçim
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      // iOS sim / macOS
        return 'http://127.0.0.1:3000';
      case TargetPlatform.android:
      // Android emulator: host makine => 10.0.2.2
        return 'http://10.0.2.2:3000';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  /// WebSocket base URL (ör: ws://localhost:3000/poker)
  static String get ws {
    if (_wsDef.isNotEmpty) return _wsDef;

    if (kIsWeb) {
      // HTTPS ise wss kullanman gerekir; dev'de çoğunlukla http/ws.
      return 'ws://localhost:3000/poker';
    }

    // Mobil/Desktop için api'den türet
    final httpBase = api; // http://host:port
    final isHttps = httpBase.startsWith('https://');
    final scheme = isHttps ? 'wss' : 'ws';
    final host = httpBase.replaceFirst(RegExp(r'^https?://'), '');
    return '$scheme://$host/poker';
  }
}
