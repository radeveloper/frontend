import 'dart:io' show Platform;

class Env {
  // flutter run --dart-define=API_BASE=http://192.168.1.10:3000
  static const apiBase = String.fromEnvironment('API_BASE');
  static const wsBase  = String.fromEnvironment('WS_BASE');

  static String get api {
    if (apiBase.isNotEmpty) return apiBase;
    // Varsayılanlar: iOS sim, Android emu, diğer cihazlar
    if (Platform.isIOS) return 'http://127.0.0.1:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get ws {
    if (wsBase.isNotEmpty) return wsBase;
    final host = api.replaceFirst(RegExp(r'^http'), 'ws');
    return '$host/poker';
  }
}
/*
Gerçek cihazda çalıştırırken:
flutter run --dart-define=API_BASE=http://<bilgisayar_IP>:3000 --dart-define=WS_BASE=ws://<bilgisayar_IP>:3000/poker*/
