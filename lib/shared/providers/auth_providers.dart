import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_providers.dart';

final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session != null);
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentUser;
});

final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.currentSession;
});
