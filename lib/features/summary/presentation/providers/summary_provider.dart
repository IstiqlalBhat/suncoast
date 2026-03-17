import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/models/session_summary_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/datasources/summary_remote_datasource.dart';
import '../../data/repositories/summary_repository.dart';

final _logger = Logger();

final summaryRemoteDatasourceProvider = Provider<SummaryRemoteDatasource>((
  ref,
) {
  return SummaryRemoteDatasource(ref.watch(supabaseClientProvider));
});

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(
    remoteDatasource: ref.watch(summaryRemoteDatasourceProvider),
    apiClient: ref.watch(apiClientProvider),
  );
});

/// Triggers summary generation in the background (fire-and-forget).
/// Call this when the session ends so the server starts processing immediately.
void triggerSummaryGeneration(WidgetRef ref, String sessionId) {
  final repo = ref.read(summaryRepositoryProvider);
  repo.generateAndFetchSummary(sessionId).then((_) {
    _logger.i('Summary generation triggered for session $sessionId');
  }).catchError((e) {
    _logger.e('Background summary generation failed: $e');
  });
}

/// Fetches the summary. If it doesn't exist yet, returns null (still processing).
/// Does NOT trigger generation — that's done by [triggerSummaryGeneration].
final summaryProvider = FutureProvider.family<SessionSummaryModel?, String>((
  ref,
  sessionId,
) async {
  final repo = ref.watch(summaryRepositoryProvider);
  final existing = await repo.getSummary(sessionId);
  if (existing.isSuccess && existing.dataOrNull != null) {
    return existing.dataOrNull;
  }
  // Not ready yet — return null so the UI can show "processing" state
  return null;
});

final summaryActivityProvider = FutureProvider.family<ActivityModel?, String>((
  ref,
  activityId,
) async {
  final activityRepo = ref.watch(activityRepositoryProvider);
  final result = await activityRepo.getActivity(activityId);
  return result.dataOrNull;
});
