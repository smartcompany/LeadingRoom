import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService shared = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<String> currentTier() async {
    final uid = user?.id;
    if (uid == null) return 'free';
    final row = await _client
        .from('lr_subscriptions')
        .select('tier')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return 'free';
    return row['tier'] as String;
  }

  Future<void> ensureSubscriptionRow() async {
    final uid = user?.id;
    if (uid == null) return;
    await _client.from('lr_subscriptions').upsert({
      'user_id': uid,
      'tier': 'free',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
