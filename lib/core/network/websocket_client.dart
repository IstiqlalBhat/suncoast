import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final _logger = Logger();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnected = false;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect({
    required String url,
    Map<String, String>? headers,
  }) async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
        protocols: headers != null ? null : null,
      );

      await _channel!.ready;
      _isConnected = true;
      _logger.i('WebSocket connected to $url');

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(decoded);
          } catch (e) {
            _logger.w('Failed to decode WebSocket message: $e');
          }
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          _logger.i('WebSocket connection closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  void send(dynamic data) {
    if (!_isConnected || _channel == null) {
      _logger.w('Cannot send: WebSocket not connected');
      return;
    }

    if (data is Map || data is List) {
      _channel!.sink.add(jsonEncode(data));
    } else {
      _channel!.sink.add(data);
    }
  }

  void sendBytes(List<int> bytes) {
    if (!_isConnected || _channel == null) {
      _logger.w('Cannot send bytes: WebSocket not connected');
      return;
    }
    _channel!.sink.add(bytes);
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
