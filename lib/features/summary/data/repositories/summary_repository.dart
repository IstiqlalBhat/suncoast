import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../../../core/utils/result.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../datasources/summary_remote_datasource.dart';

class SummaryRepository {
  final SummaryRemoteDatasource _remoteDatasource;
  final _logger = Logger();

  SummaryRepository({
    required SummaryRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource,
       super();

  Future<Result<SessionSummaryModel>> generateAndFetchSummary(
    String sessionId,
  ) async {
    try {
      // Call generateSummary via HTTP (bypasses Firebase callable SDK issues)
      final url = Uri.parse(
        'https://us-central1-alchemy-4bc7c.cloudfunctions.net/generateSummary',
      );
      final httpResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': {'sessionId': sessionId}}),
      );

      if (httpResponse.statusCode != 200) {
        _logger.e('Summary HTTP error: ${httpResponse.statusCode} ${httpResponse.body}');
        return Result.failure('Summary generation failed (${httpResponse.statusCode})');
      }

      final responseBody = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      final result = responseBody['result'] as Map<String, dynamic>?;
      final inlineSummary = result?['summary'];

      if (inlineSummary is Map) {
        return Result.success(
          SessionSummaryModel.fromJson(
            Map<String, dynamic>.from(inlineSummary),
          ),
        );
      }

      // Fetch the generated summary from Supabase as fallback
      final summary = await _remoteDatasource.getSummary(sessionId);
      if (summary == null) {
        return const Result.failure('Summary not found after generation');
      }
      return Result.success(summary);
    } catch (e) {
      _logger.e('generateAndFetchSummary failed: $e');
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
