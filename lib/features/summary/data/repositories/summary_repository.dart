import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../datasources/summary_remote_datasource.dart';

class SummaryRepository {
  final SummaryRemoteDatasource _remoteDatasource;
  final ApiClient _apiClient;

  const SummaryRepository({
    required SummaryRemoteDatasource remoteDatasource,
    required ApiClient apiClient,
  })  : _remoteDatasource = remoteDatasource,
        _apiClient = apiClient;

  Future<Result<SessionSummaryModel>> generateAndFetchSummary(
    String sessionId,
  ) async {
    try {
      // Call Firebase Cloud Function to generate summary
      await _apiClient.callFunction(
        ApiEndpoints.generateSummary,
        data: {'sessionId': sessionId},
      );

      // Fetch the generated summary from Supabase
      final summary = await _remoteDatasource.getSummary(sessionId);
      if (summary == null) {
        return Result.failure('Summary not found after generation');
      }
      return Result.success(summary);
    } catch (e) {
      return Result.failure('Failed to generate summary: $e');
    }
  }

  Future<Result<SessionSummaryModel>> getSummary(String sessionId) async {
    try {
      final summary = await _remoteDatasource.getSummary(sessionId);
      if (summary == null) {
        return Result.failure('Summary not found');
      }
      return Result.success(summary);
    } catch (e) {
      return Result.failure('Failed to fetch summary: $e');
    }
  }
}
