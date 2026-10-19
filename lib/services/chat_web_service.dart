import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_client/web_socket_client.dart';


const String _wsUrl = String.fromEnvironment(
  'WS_URL',
  defaultValue: 'ws://localhost:8000/ws/chat',
);

enum ConnectionStatus { connecting, connected, reconnecting, disconnected }

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


  final ValueNotifier<ConnectionStatus> status =
      ValueNotifier(ConnectionStatus.connecting);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Stream<void> get connectionLostStream => _connectionLostController.stream;

  Uri _buildUri() {
    final raw = _wsUrl.trim();
    final urlWithScheme = raw.contains('://') ? raw : 'ws://$raw';
    final parsed = Uri.parse(urlWithScheme);
    if (parsed.path.isEmpty || parsed.path == '/') {
      return parsed.replace(path: '/ws/chat');
    }
    return parsed;
  }

  void connect() {
    final socket = WebSocket(
      _buildUri(),
      backoff: ConstantBackoff(const Duration(seconds: 2)),
    );
    _socket = socket;

    _messageSub = socket.messages.listen((message) {
      try {
        final data = json.decode(message);
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        }
      } catch (_) {}
    });

    _connectionSub = socket.connection.listen((state) {
      if (state is Connected || state is Reconnected) {
        status.value = ConnectionStatus.connected;
      } else if (state is Reconnecting) {
        status.value = ConnectionStatus.reconnecting;
        _connectionLostController.add(null);
      } else if (state is Disconnected) {
        status.value = ConnectionStatus.disconnected;
        _connectionLostController.add(null);
      } else if (state is Connecting) {
        status.value = ConnectionStatus.connecting;
      }
    });
  }

  Future<void> sendChat(String id, String query, List<Map<String, String>> history, String focus) async {
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
      'history': history,
      'focus': focus,
    }));
  }

  void dispose() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket?.close();
    _messageController.close();
    _connectionLostController.close();
    status.dispose();
  }
}