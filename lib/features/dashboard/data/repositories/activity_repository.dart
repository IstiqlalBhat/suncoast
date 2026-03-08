import '../../../../core/utils/result.dart';
import '../../../../shared/models/activity_model.dart';
import '../datasources/activity_remote_datasource.dart';

class ActivityRepository {
  final ActivityRemoteDatasource _remoteDatasource;

  const ActivityRepository({
    required ActivityRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  Future<Result<List<ActivityModel>>> getActivities({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    ActivityType? typeFilter,
  }) async {
    try {
      final activities = await _remoteDatasource.getActivities(
        offset: offset,
        limit: limit,
        searchQuery: searchQuery,
        typeFilter: typeFilter,
      );
      return Result.success(activities);
    } catch (e) {
      return Result.failure('Failed to load activities: $e');
    }
  }

  Future<Result<ActivityModel>> getActivity(String id) async {
    try {
      final activity = await _remoteDatasource.getActivity(id);
      return Result.success(activity);
    } catch (e) {
      return Result.failure('Failed to load activity: $e');
    }
  }

  Future<Result<ActivityModel>> createActivity({
    required String title,
    required ActivityType type,
    String? description,
    String? location,
  }) async {
    try {
      final activity = await _remoteDatasource.createActivity(
        title: title,
        type: type,
        description: description,
        location: location,
      );
      return Result.success(activity);
    } catch (e) {
      return Result.failure('Failed to create activity: $e');
    }
  }
}
