import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_client/web_socket_client.dart';

final chatWebServiceProvider = Provider<ChatWebService>((ref) {
  final service = ChatWebService()..connect();
  ref.onDispose(service.dispose);
  return service;
});

class ChatWebService {
  WebSocket? _socket;
  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionLostController = StreamController<void>.broadcast();

  /// Every decoded server message. Each one carries an `id` so the notifier
  /// can route it to the right turn.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Fires whenever the connection drops, so in-flight turns can be failed.
  Stream<void> get connectionLostStream => _connectionLostController.stream;

  void connect() {
    final socket = WebSocket(Uri.parse('ws://localhost:8000/ws/chat'));
    _socket = socket;

    _messageSub = socket.messages.listen((message) {
      try {
        final data = json.decode(message);
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        }
      } catch (_) {
        // Ignore malformed frames.
      }
    });

    _connectionSub = socket.connection.listen((state) {
      if (state is Reconnecting || state is Disconnected) {
        _connectionLostController.add(null);
      }
    });
  }

  /// Sends a chat request, waiting for the socket to be connected first.
  /// Throws if the connection isn't ready within 10 seconds.
  Future<void> sendChat(String id, String query) async {
    final socket = _socket;
    if (socket == null) throw StateError('Socket not created');

    final state = socket.connection.state;
    if (state is! Connected && state is! Reconnected) {
      await socket.connection
          .firstWhere((s) => s is Connected || s is Reconnected)
          .timeout(const Duration(seconds: 10));
    }

    socket.send(json.encode({
      'type': 'chat',
      'id': id,
      'query': query,
      'history': [],
      'focus': 'all',
    }));
  }

  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket?.close();
    _messageController.close();
    _connectionLostController.close();
  }
}