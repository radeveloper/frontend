class AppValidators {
  static String? notEmpty(String? v, {String msg = 'This field is required'}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  // Örnek Room ID: alfanümerik, alt çizgi/eksi serbest, 4–20 karakter
  static String? roomId(String? v, {String msg = 'Invalid Room ID'}) {
    if (v == null || v.trim().isEmpty) return 'Room ID is required';
    final ok = RegExp(r'^[A-Za-z0-9_-]{4,20}$').hasMatch(v.trim());
    return ok ? null : msg;
  }
}
