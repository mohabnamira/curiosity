import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/services/chat_web_service.dart';

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

class ChatState {
  final List<Turn> turns;
  final String? activeTurnId;

  const ChatState({this.turns = const [], this.activeTurnId});

  Turn? get activeTurn {
    if (activeTurnId == null) return null;
    try {
      return turns.firstWhere((t) => t.id == activeTurnId);
    } catch (_) {
      return null;
    }
  }

  ChatState copyWith({List<Turn>? turns, String? activeTurnId}) {
    return ChatState(
      turns: turns ?? this.turns,
      activeTurnId: activeTurnId ?? this.activeTurnId,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  StreamSubscription? _subscription;

  @override
  ChatState build() {
    final webService = ref.watch(chatWebServiceProvider);
    _subscription?.cancel();
    _subscription = webService.messageStream.listen(_handleMessage);
    ref.onDispose(() => _subscription?.cancel());
    return const ChatState();
  }

  String sendQuery(String query) {
    final webService = ref.read(chatWebServiceProvider);
    final id = webService.sendChat(query);
    
    final newTurn = Turn(
      id: id,
      question: query,
      status: TurnStatus.searching,
    );

    state = state.copyWith(
      turns: [...state.turns, newTurn],
      activeTurnId: id,
    );
    return id;
  }

  void setActiveTurn(String id) {
    state = state.copyWith(activeTurnId: id);
  }

  void _handleMessage(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final type = data['type']?.toString();
    if (id == null || type == null) return;

    final turnIndex = state.turns.indexWhere((t) => t.id == id);
    if (turnIndex == -1) return;

    final turn = state.turns[turnIndex];
    Turn updatedTurn = turn;

    if (type == 'search_results') {
      final rawResults = data['data'];
      if (rawResults is List) {
        final sources = rawResults
            .where((item) => item is Map)
            .map((item) => Source.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        updatedTurn = turn.copyWith(sources: sources);
      }
    } else if (type == 'content') {
      final chunk = data['data']?.toString() ?? '';
      updatedTurn = turn.copyWith(
        answer: turn.answer + chunk,
        status: TurnStatus.generating,
      );
    } else if (type == 'done') {
      updatedTurn = turn.copyWith(status: TurnStatus.done);
    } else if (type == 'error') {
      final errorMsg = data['data']?.toString() ?? 'Unknown error';
      updatedTurn = turn.copyWith(
        status: TurnStatus.error,
        errorMessage: errorMsg,
      );
    }

    final updatedTurns = List<Turn>.from(state.turns);
    updatedTurns[turnIndex] = updatedTurn;
    state = state.copyWith(turns: updatedTurns);
  }
}