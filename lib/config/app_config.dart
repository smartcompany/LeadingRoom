import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();
  static final AppConfig shared = AppConfig._();

  String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    if (v == null || v.isEmpty) {
      throw StateError('SUPABASE_URL missing in .env');
    }
    return v;
  }

  String get supabasePublishableKey {
    final v = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    if (v == null || v.isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY missing in .env');
    }
    return v;
  }

  String get apiBaseUrl {
    final v = dotenv.env['API_BASE_URL'];
    if (v == null || v.isEmpty) {
      throw StateError('API_BASE_URL missing in .env');
    }
    return v;
  }
}
