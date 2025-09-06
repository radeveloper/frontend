
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';

class RoomsApi {
  RoomsApi(this.api);
  final ApiClient api;

  Future<String> createRoom(String name, {String deckType='fibonacci'}) async {
    final res = await api.post('/api/v1/rooms', {'name': name, 'deckType': deckType});
    final code = res['code'] as String;
    final participantId = res['participantId'] as String;
    Session.I.roomCode = code;
    Session.I.participantId = res['participantId'] as String?;
    if (kDebugMode) {
      print("CREATE ROOM - ROOM CODE : $code");
      print("CREATE ROOM - PARTICIPANT :$participantId");
    }
    return code;
  }

  Future<String> joinRoom(String code, String displayName) async {
    final res = await api.post('/api/v1/rooms/$code/join', {'displayName': displayName});
    Session.I.roomCode = code;
    Session.I.participantId = res['participantId'] as String?;
    if (kDebugMode) {
      print("JOIN ROOM - ROOM CODE : $code");
      print("JOIN ROOM - PARTICIPANT :${Session.I.participantId}");
    }
    return code;
  }
}
