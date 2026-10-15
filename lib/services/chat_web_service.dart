import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_client/web_socket_client.dart';

final chatWebServiceProvider = Provider<ChatWebService>((ref) {
  final service = ChatWebService();
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});

class ChatWebService {
  WebSocket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  void connect() {
    _socket = WebSocket(Uri.parse('ws://localhost:8000/ws/chat'));
    _socket!.messages.listen((message) {
      try {
        final data = json.decode(message);
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        }
      } catch (_) {}
    });
  }

  String sendChat(String query) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _socket?.send(json.encode({
      'type': 'chat',
      'id': id,
      'query': query,
      'history': [],
      'focus': 'all',
    }));
    return id;
  }

  void dispose() {
    _socket?.close();
    _messageController.close();
  }
}