import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/activity_model.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../data/repositories/activity_repository.dart';

final activityRemoteDatasourceProvider = Provider<ActivityRemoteDatasource>((ref) {
  return ActivityRemoteDatasource(ref.watch(supabaseClientProvider));
});

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    remoteDatasource: ref.watch(activityRemoteDatasourceProvider),
  );
});

final activitiesProvider = AsyncNotifierProvider<ActivitiesNotifier, List<ActivityModel>>(
  ActivitiesNotifier.new,
);

class ActivitiesNotifier extends AsyncNotifier<List<ActivityModel>> {
  @override
  Future<List<ActivityModel>> build() async {
    return _fetchActivities();
  }

  Future<List<ActivityModel>> _fetchActivities({
    String? searchQuery,
    ActivityType? typeFilter,
  }) async {
    final repo = ref.read(activityRepositoryProvider);
    final result = await repo.getActivities(
      searchQuery: searchQuery,
      typeFilter: typeFilter,
    );
    return result.when(
      success: (data) => data,
      failure: (message, _) => throw Exception(message),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchActivities());
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchActivities(searchQuery: query.isEmpty ? null : query),
    );
  }

  Future<void> filterByType(ActivityType? type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchActivities(typeFilter: type),
    );
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedTypeFilterProvider = StateProvider<ActivityType?>((ref) => null);
