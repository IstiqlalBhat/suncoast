import 'package:logger/logger.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../datasources/summary_remote_datasource.dart';

class SummaryRepository {
  final SummaryRemoteDatasource _remoteDatasource;
  final ApiClient _apiClient;
  final _logger = Logger();

  SummaryRepository({
    required SummaryRemoteDatasource remoteDatasource,
    required ApiClient apiClient,
  }) : _remoteDatasource = remoteDatasource,
       _apiClient = apiClient,
       super();

  Future<Result<SessionSummaryModel>> generateAndFetchSummary(
    String sessionId,
  ) async {
    try {
      final result = await _apiClient.callFunction(
        'generateSummary',
        data: {'sessionId': sessionId},
      );
      final summary = await _waitForSummary(sessionId);
      if (summary == null) {
        final inlineSummary = result['summary'];
        if (inlineSummary is Map) {
          return Result.success(
            SessionSummaryModel.fromJson(
              _normalizeJsonMap(inlineSummary),
            ),
          );
        }
        return const Result.failure('Summary not found after generation');
      }
      return Result.success(summary);
    } catch (e) {
      try {
        final summary = await _waitForSummary(sessionId);
        if (summary != null) {
          return Result.success(summary);
        }
      } catch (_) {}
      _logger.e('generateAndFetchSummary failed: $e');
      return Result.failure('Failed to generate summary: $e');
    }
  }

  Future<SessionSummaryModel?> _waitForSummary(String sessionId) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      final summary = await _remoteDatasource.getSummary(sessionId);
      if (summary != null) {
        return summary;
      }

      if (attempt < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    return null;
  }

  Map<String, dynamic> _normalizeJsonMap(Map input) {
    return input.map(
      (key, value) => MapEntry(key.toString(), _normalizeJsonValue(value)),
    );
  }

  Object? _normalizeJsonValue(Object? value) {
    if (value is Map) {
      return _normalizeJsonMap(value);
    }
    if (value is List) {
      return value.map(_normalizeJsonValue).toList();
    }
    return value;
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

  Future<Result<SessionSummaryModel>> updateSummary(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final summary = await _remoteDatasource.updateSummary(sessionId, fields);
      return Result.success(summary);
    } catch (e) {
      return Result.failure('Failed to update summary: $e');
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
