import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/models/activity_model.dart';

class ActivityRemoteDatasource {
  final SupabaseClient _supabase;

  const ActivityRemoteDatasource(this._supabase);

  Future<List<ActivityModel>> getActivities({
    int offset = 0,
    int limit = 20,
    String? searchQuery,
    ActivityType? typeFilter,
  }) async {
    try {
      var query = _supabase
          .from(ApiEndpoints.activitiesTable)
          .select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      if (typeFilter != null) {
        query = query.eq('type', typeFilter.name);
      }

      final response = await query
          .order('scheduled_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ActivityModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch activities: $e');
    }
  }

  Future<ActivityModel> getActivity(String id) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.activitiesTable)
          .select()
          .eq('id', id)
          .single();

      return ActivityModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch activity: $e');
    }
  }

  Future<ActivityModel> createActivity({
    required String title,
    required ActivityType type,
    String? description,
    String? location,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final orgId = userId != null
          ? (await _supabase
              .from('profiles')
              .select('org_id')
              .eq('id', userId)
              .single())['org_id']
          : null;

      final response = await _supabase
          .from(ApiEndpoints.activitiesTable)
          .insert({
            'title': title,
            'type': type.name,
            'description': description,
            'location': location,
            'status': 'pending',
            'assigned_to': userId,
            'org_id': orgId,
            'scheduled_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ActivityModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create activity: $e');
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _supabase.from(ApiEndpoints.activitiesTable).delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete activity: $e');
    }
  }

  Future<ActivityModel> updateActivityStatus(String id, String status) async {
    try {
      final response = await _supabase
          .from(ApiEndpoints.activitiesTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return ActivityModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update activity status: $e');
    }
  }
}
