import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // A getter, not a field initializer: reading Supabase.instance.client
  // must be deferred until a method is actually called, since these
  // service objects can be constructed (e.g. as State fields) before
  // Supabase.initialize() has necessarily run.
  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  /// Staff sign in with the username + password their shop owner set for
  /// them in the web dashboard's Add Staff form (not Google OAuth, which
  /// stays owner/customer-only on the web app). Supabase Auth itself only
  /// understands email + password, so we first resolve the username to its
  /// backing email via a SECURITY DEFINER RPC that's safe to call while
  /// unauthenticated.
  Future<void> signInWithUsername(String username, String password) async {
    final email = await _client.rpc(
      'resolve_staff_email',
      params: {'p_username': username},
    ) as String?;

    if (email == null) {
      throw Exception('Invalid username or password.');
    }

    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
