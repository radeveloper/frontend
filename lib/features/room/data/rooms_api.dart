import '../../../core/network/api_client.dart';
import '../../../core/session/session.dart';

class RoomsApi {
  RoomsApi(this.api);
  final ApiClient api;

  Future<String> createRoom(String name, {String deckType='fibonacci'}) async {
    final res = await api.post('/api/v1/rooms', {'name': name, 'deckType': deckType});
    final code = res['code'] as String;
    Session.I.roomCode = code;
    Session.I.participantId = res['participantId'] as String?;
    return code;
  }

  Future<String> joinRoom(String code, String displayName) async {
    final res = await api.post('/api/v1/rooms/$code/join', {'displayName': displayName});
    Session.I.roomCode = code;
    Session.I.participantId = res['participantId'] as String?;
    return code;
  }
}
