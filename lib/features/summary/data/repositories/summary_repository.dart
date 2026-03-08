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
  }) : _remoteDatasource = remoteDatasource,
       _apiClient = apiClient;

  Future<Result<SessionSummaryModel>> generateAndFetchSummary(
    String sessionId,
  ) async {
    try {
      // Call Firebase Cloud Function to generate summary
      final response = await _apiClient.callFunction(
        ApiEndpoints.generateSummary,
        data: {'sessionId': sessionId},
      );

      final inlineSummary = response['summary'];
      if (inlineSummary is Map) {
        return Result.success(
          SessionSummaryModel.fromJson(
            Map<String, dynamic>.from(inlineSummary),
          ),
        );
      }

      // Fetch the generated summary from Supabase
      final summary = await _remoteDatasource.getSummary(sessionId);
      if (summary == null) {
        return const Result.failure('Summary not found after generation');
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
        return const Result.failure('Summary not found');
      }
      return Result.success(summary);
    } catch (e) {
      return Result.failure('Failed to fetch summary: $e');
    }
  }

  Future<Result<void>> confirmSummary(String sessionId) async {
    try {
      await _remoteDatasource.confirmSummary(sessionId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure('Failed to confirm summary: $e');
    }
  }
}
