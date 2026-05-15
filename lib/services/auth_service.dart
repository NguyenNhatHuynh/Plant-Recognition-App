import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient? _client;

  const AuthService({SupabaseClient? client}) : _client = client;

  bool get isConfigured => _client != null;

  Session? get currentSession => _client?.auth.currentSession;

  User? get currentUser => _client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    if (_client == null) {
      return const Stream<AuthState>.empty();
    }
    return _client.auth.onAuthStateChange;
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to your environment.',
      );
    }
    return client;
  }
}
