import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../session/session.dart';

class ApiClient {
  final http.Client _http;
  ApiClient([http.Client? httpClient]) : _http = httpClient ?? http.Client();

  Uri _u(String p) => Uri.parse('${Env.api}$p');
  Map<String,String> _h() => {
    'content-type': 'application/json',
    if (Session.I.token != null) 'authorization': 'Bearer ${Session.I.token}',
  };

  Future<Map<String,dynamic>> post(String path, Map body) async {
    final r = await _http.post(_u(path), headers: _h(), body: jsonEncode(body));
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body);
    throw Exception('POST $path failed: ${r.statusCode} ${r.body}');
  }

  Future<Map<String,dynamic>> get(String path) async {
    final r = await _http.get(_u(path), headers: _h());
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body);
    throw Exception('GET $path failed: ${r.statusCode} ${r.body}');
  }
}
