import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';

class ApiClient {
  final SupabaseClient _supabase;
  final Dio _dio;
  final FirebaseFunctions? _functionsOverride;

  ApiClient({
    required SupabaseClient supabase,
    required Dio dio,
    FirebaseFunctions? functions,
  }) : _supabase = supabase,
       _dio = dio,
       _functionsOverride = functions;

  /// Lazily access FirebaseFunctions to avoid accessing it before Firebase.initializeApp()
  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  SupabaseClient get supabase => _supabase;
  Dio get dio => _dio;

  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get accessToken => _supabase.auth.currentSession?.accessToken;

  /// Call a Firebase v2 callable function via the Firebase SDK
  Future<Map<String, dynamic>> callFunction(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    // Strip leading slash if present
    final name = functionName.startsWith('/')
        ? functionName.substring(1)
        : functionName;

    final callable = _functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );

    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Call the Deepgram proxy directly via HTTP (not callable, it's an onRequest function)
  Future<Map<String, dynamic>> callDeepgramProxy(List<int> audioBytes) async {
    final response = await _dio.post(
      '${AppConfig.firebaseFunctionsUrl}${ApiEndpoints.deepgramProxy}',
      data: audioBytes,
      options: Options(
        headers: {
          'Content-Type':
              'audio/raw;encoding=linear16;sample_rate=16000;channels=1',
        },
        responseType: ResponseType.json,
      ),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  static Dio createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }
}
