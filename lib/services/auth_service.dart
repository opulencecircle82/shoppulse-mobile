import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // A getter, not a field initializer: reading Supabase.instance.client
  // must be deferred until a method is actually called, since these
  // service objects can be constructed (e.g. as State fields) before
  // Supabase.initialize() has necessarily run.
  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.shoppulse.mobile://login-callback',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
