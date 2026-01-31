import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket service for real-time data from Go Core.
class WebSocketService {
  WebSocketService({this.url = 'ws://localhost:8090/ws'});

  final String url;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  /// Stream of events from the WebSocket.
  Stream<Map<String, dynamic>> get stream {
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();
    _connect();
    return _controller!.stream;
  }

  /// Whether the WebSocket is connected.
  bool get isConnected => _isConnected;

  void _connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            _controller?.add(json);
          } catch (e) {
            // Ignore parse errors
          }
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _channel = null;

    // Exponential backoff: 1s, 2s, 4s, 8s, max 30s
    final delay = Duration(
      seconds: (1 << _reconnectAttempts).clamp(1, 30),
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  /// Close the WebSocket connection.
  void dispose() {
    _reconnectTimer?.cancel();
    _controller?.close();
    _channel?.sink.close();
  }
}

/// Event types from Go Core WebSocket.
class WSEventType {
  static const String stats = 'stats';
  static const String alert = 'alert';
  static const String connection = 'connection';
}
