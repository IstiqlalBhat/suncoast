import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart' as app_exceptions;

class AuthRemoteDatasource {
  final SupabaseClient _supabase;

  const AuthRemoteDatasource(this._supabase);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ServerException('Sign in failed: $e');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw app_exceptions.ServerException('Sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw app_exceptions.ServerException('Sign out failed: $e');
    }
  }

  Future<Session?> recoverSession() async {
    return _supabase.auth.currentSession;
  }

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
}
