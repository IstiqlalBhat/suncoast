import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/datasources/summary_remote_datasource.dart';
import '../../data/repositories/summary_repository.dart';

final summaryRemoteDatasourceProvider = Provider<SummaryRemoteDatasource>((ref) {
  return SummaryRemoteDatasource(ref.watch(supabaseClientProvider));
});

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(
    remoteDatasource: ref.watch(summaryRemoteDatasourceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

final summaryProvider = FutureProvider.family<SessionSummaryModel?, String>(
  (ref, sessionId) async {
    final repo = ref.watch(summaryRepositoryProvider);

    // Try to get existing summary first
    final existing = await repo.getSummary(sessionId);
    if (existing.isSuccess && existing.dataOrNull != null) {
      return existing.dataOrNull;
    }

    // Generate new summary
    final result = await repo.generateAndFetchSummary(sessionId);
    return result.dataOrNull;
  },
);
