import 'dart:convert';

import 'package:http/http.dart' as http;

class AppConfig {
  AppConfig._();
  static final AppConfig shared = AppConfig._();

  /// 서버만 호출 — 로컬 .env 없음.
  static const apiBaseUrl = 'https://leading-room-server.vercel.app';

  String? _supabaseUrl;
  String? _supabasePublishableKey;

  String get supabaseUrl {
    final v = _supabaseUrl;
    if (v == null || v.isEmpty) {
      throw StateError('AppConfig not loaded. Call loadFromServer() first.');
    }
    return v;
  }

  String get supabasePublishableKey {
    final v = _supabasePublishableKey;
    if (v == null || v.isEmpty) {
      throw StateError('AppConfig not loaded. Call loadFromServer() first.');
    }
    return v;
  }

  Future<void> loadFromServer() async {
    final uri = Uri.parse('$apiBaseUrl/api/config');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw StateError('config failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final url = body['supabaseUrl'] as String?;
    final key = body['supabasePublishableKey'] as String?;
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError('config missing supabase fields');
    }
    _supabaseUrl = url;
    _supabasePublishableKey = key;
  }
}
