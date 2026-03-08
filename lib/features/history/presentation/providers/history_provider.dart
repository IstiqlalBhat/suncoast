import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/app_providers.dart';

final sessionHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('sessions')
      .select('*, activities(title, type)')
      .eq('user_id', supabase.auth.currentUser!.id)
      .order('started_at', ascending: false)
      .limit(50);

  return List<Map<String, dynamic>>.from(response);
});
