import 'dart:async';
import 'package:web_socket_client/web_socket_client.dart';
import 'dart:convert';


class ChatWebService {
  static final _instance = ChatWebService._internal();
  WebSocket? _socket;
  factory ChatWebService() => _instance;
  ChatWebService._internal();
  final _searchResultsController = StreamController<Map<String, dynamic>>.broadcast();
  final _contentController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get searchResults => _searchResultsController.stream;
  Stream<Map<String, dynamic>> get contentStream => _contentController.stream;

  void connect() {
    _socket = WebSocket(Uri.parse('ws://localhost:8000/ws/chat'));
    _socket!.messages.listen((message) {
      final data = json.decode(message);
      if (data['type'] == 'search_results') {
        _searchResultsController.add(data);
      } else if (data['type'] == 'content') {
        _contentController.add(data);
      }
    });
  }

  void chat(String query) {
    _socket!.send(json.encode({'query': query}));
  }
}