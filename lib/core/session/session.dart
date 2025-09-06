class Session {
  Session._();
  static final I = Session._();

  String? token;
  String? displayName;
  String? roomCode;
  String? participantId;

  void clear() { token=null; displayName=null; roomCode=null; participantId=null; }
}
