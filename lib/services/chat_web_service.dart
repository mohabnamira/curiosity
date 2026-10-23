import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_client/web_socket_client.dart';

/// Production backend URL. Replace with your actual Render deployment URL.
const String kProductionServerUrl = 'wss://REPLACE-ME.onrender.com';

/// Server URL resolution:
/// a) String.fromEnvironment('SERVER_URL') if non-empty (developer override)
/// b) else if kDebugMode -> 'localhost:8000'
/// c) else -> kProductionServerUrl
String get defaultServerUrl {
  const envUrl = String.fromEnvironment('SERVER_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  if (kDebugMode) {
    return 'localhost:8000';
  }
  return kProductionServerUrl;
}

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
  String? _customUrl;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionLostController = StreamController<void>.broadcast();

  final ValueNotifier<ConnectionStatus> status =
      ValueNotifier(ConnectionStatus.connecting);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Stream<void> get connectionLostStream => _connectionLostController.stream;

  Uri? _buildUri() {
    final raw = (_customUrl?.trim().isNotEmpty == true)
        ? _customUrl!.trim()
        : defaultServerUrl;

    if (raw.trim().isEmpty || raw.contains('REPLACE-ME')) {
      return null;
    }

    // Support ws://, wss://, http://, https:// or bare host:port
    String normalized = raw.trim();
    if (normalized.startsWith('http://')) {
      normalized = 'ws://${normalized.substring(7)}';
    } else if (normalized.startsWith('https://')) {
      normalized = 'wss://${normalized.substring(8)}';
    } else if (!normalized.startsWith('ws://') && !normalized.startsWith('wss://')) {
      normalized = 'ws://$normalized';
    }

    final parsed = Uri.parse(normalized);
    if (parsed.path.isEmpty || parsed.path == '/') {
      return parsed.replace(path: '/ws/chat');
    }
    return parsed;
  }

  void updateServerUrl(String? newUrl) {
    _customUrl = newUrl;
    reconnect();
  }

  void reconnect() {
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket?.close();
    _socket = null;
    status.value = ConnectionStatus.connecting;
    connect();
  }

  void connect() {
    final uri = _buildUri();
    if (uri == null) {
      status.value = ConnectionStatus.disconnected;
      return;
    }

    final socket = WebSocket(
      uri,
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

  Future<void> sendChat(
    String id,
    String query,
    List<Map<String, String>> history,
    String focus, {
    int maxResults = 5,
  }) async {
    final socket = _socket;
    if (socket == null) {
      throw StateError('Could not reach the server');
    }

    final state = socket.connection.state;
    if (state is! Connected && state is! Reconnected) {
      await socket.connection
          .firstWhere((s) => s is Connected || s is Reconnected)
          .timeout(const Duration(seconds: 45));
    }

    socket.send(json.encode({
      'type': 'chat',
      'id': id,
      'query': query,
      'history': history,
      'focus': focus,
      'max_results': maxResults,
    }));
  }

  void sendCancel(String id) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.send(json.encode({
        'type': 'cancel',
        'id': id,
      }));
    } catch (_) {}
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
