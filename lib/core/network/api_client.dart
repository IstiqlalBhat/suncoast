import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;
import '../config/app_config.dart';

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

  Future<String?> getValidAccessToken({bool forceRefresh = false}) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return null;
    }

    if (!forceRefresh && !session.isExpired) {
      return session.accessToken;
    }

    try {
      final refreshed = await _supabase.auth.refreshSession();
      return refreshed.session?.accessToken ??
          _supabase.auth.currentSession?.accessToken;
    } catch (_) {
      return _supabase.auth.currentSession?.accessToken;
    }
  }

  /// Call a Firebase v2 callable function via the Firebase SDK
  Future<Map<String, dynamic>> callFunction(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    return _callFunctionWithAuth(
      functionName,
      data: data,
      forceRefresh: false,
    );
  }

  Future<Map<String, dynamic>> _callFunctionWithAuth(
    String functionName, {
    Map<String, dynamic>? data,
    required bool forceRefresh,
  }) async {
    // Strip leading slash if present
    final name = functionName.startsWith('/')
        ? functionName.substring(1)
        : functionName;

    final token = await getValidAccessToken(forceRefresh: forceRefresh);

    final payload = {
      ...?data,
      ...?token != null ? {'accessToken': token} : null,
    };

    final callable = _functions.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );

    try {
      final result = await callable.call(payload);
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      if (!forceRefresh && error.code == 'unauthenticated') {
        return _callFunctionWithAuth(
          functionName,
          data: data,
          forceRefresh: true,
        );
      }
      rethrow;
    }
  }

  /// Transcribe audio via the Whisper proxy (onRequest function).
  /// Returns {"transcript": "..."}.
  Future<Map<String, dynamic>> transcribeAudio(List<int> audioBytes) async {
    final pcm = Uint8List.fromList(audioBytes);
    final wav = _wrapPcmAsWav(pcm);

    final url = Uri.parse(AppConfig.whisperProxyUrl);
    final response = await _postAuthorizedBytes(
      url,
      body: wav,
      contentType: 'audio/wav',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Whisper proxy returned ${response.statusCode}: ${response.body}',
      );
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
  }

  Future<http.Response> _postAuthorizedBytes(
    Uri url, {
    required Uint8List body,
    required String contentType,
    bool forceRefresh = false,
  }) async {
    final token = await getValidAccessToken(forceRefresh: forceRefresh);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': contentType,
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 401 && !forceRefresh) {
      return _postAuthorizedBytes(
        url,
        body: body,
        contentType: contentType,
        forceRefresh: true,
      );
    }

    return response;
  }

  /// Wrap raw PCM16 mono 16kHz data in a WAV container.
  static Uint8List _wrapPcmAsWav(Uint8List pcmData) {
    const sampleRate = 16000;
    const numChannels = 1;
    const bitsPerSample = 16;
    const byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    const blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt sub-chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // sub-chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data sub-chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, pcmData);
    return wav;
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
