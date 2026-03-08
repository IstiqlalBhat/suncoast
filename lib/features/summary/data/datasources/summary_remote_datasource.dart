import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/session_summary_model.dart';

class SummaryRemoteDatasource {
  final SupabaseClient _supabase;

  const SummaryRemoteDatasource(this._supabase);

  Future<SessionSummaryModel?> getSummary(String sessionId) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.sessionSummariesTable)
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();

      if (response == null) return null;
      return SessionSummaryModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch summary: $e');
    }
  }

  Future<void> confirmSummary(String sessionId) async {
    try {
      await _supabase
          .from(ApiEndpoints.sessionSummariesTable)
          .update({'confirmed_at': DateTime.now().toIso8601String()})
          .eq('session_id', sessionId);
    } catch (e) {
      throw ServerException('Failed to confirm summary: $e');
    }
  }
}
