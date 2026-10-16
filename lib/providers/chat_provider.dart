import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/services/chat_web_service.dart';

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatState {
  final List<Turn> turns;
  final String? activeTurnId;
  final int? highlightedSourceIndex;

  const ChatState({
    this.turns = const [],
    this.activeTurnId,
    this.highlightedSourceIndex,
  });

  Turn? get activeTurn {
    if (activeTurnId == null) return null;
    for (final t in turns) {
      if (t.id == activeTurnId) return t;
    }
    return null;
  }

  ChatState copyWith({
    List<Turn>? turns,
    String? activeTurnId,
    int? highlightedSourceIndex,
    bool clearHighlight = false,
  }) {
    return ChatState(
      turns: turns ?? this.turns,
      activeTurnId: activeTurnId ?? this.activeTurnId,
      highlightedSourceIndex: clearHighlight
          ? null
          : (highlightedSourceIndex ?? this.highlightedSourceIndex),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final webService = ref.watch(chatWebServiceProvider);

    final messageSub = webService.messageStream.listen(_handleMessage);
    final lostSub = webService.connectionLostStream
        .listen((_) => _failInFlightTurns('Connection lost'));

    ref.onDispose(() {
      messageSub.cancel();
      lostSub.cancel();
    });

    return const ChatState();
  }

  String sendQuery(String query) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    state = state.copyWith(
      turns: [...state.turns, Turn(id: id, question: query)],
      activeTurnId: id,
      clearHighlight: true,
    );

    ref.read(chatWebServiceProvider).sendChat(id, query).catchError((_) {
      _failTurn(id, 'Could not reach the server');
    });

    return id;
  }

  void setActiveTurn(String id) {
    state = state.copyWith(activeTurnId: id, clearHighlight: true);
  }

  void setHighlightedSource(int? index) {
    state = state.copyWith(highlightedSourceIndex: index);
  }

  void _handleMessage(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final type = data['type']?.toString();
    if (id == null || type == null) return;

    final turn = _findTurn(id);
    if (turn == null || !turn.isInFlight) return;

    Turn? updated;

    switch (type) {
      case 'search_results':
        final raw = data['data'];
        if (raw is List) {
          final sources = raw
              .whereType<Map>()
              .map((item) => Source.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          updated = turn.copyWith(
            sources: sources,
            status: TurnStatus.generating,
          );
        }
      case 'content':
        updated = turn.copyWith(
          answer: turn.answer + (data['data']?.toString() ?? ''),
          status: TurnStatus.generating,
        );
      case 'done':
        updated = turn.copyWith(status: TurnStatus.done);
      case 'error':
        updated = turn.copyWith(
          status: TurnStatus.error,
          errorMessage: data['data']?.toString() ?? 'Unknown error',
        );
    }

    if (updated != null) _replaceTurn(updated);
  }

  void _failTurn(String id, String message) {
    final turn = _findTurn(id);
    if (turn == null || !turn.isInFlight) return;
    _replaceTurn(
      turn.copyWith(status: TurnStatus.error, errorMessage: message),
    );
  }

  void _failInFlightTurns(String message) {
    for (final turn in state.turns.where((t) => t.isInFlight).toList()) {
      _failTurn(turn.id, message);
    }
  }

  Turn? _findTurn(String id) {
    for (final t in state.turns) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _replaceTurn(Turn updated) {
    state = state.copyWith(
      turns: [
        for (final t in state.turns)
          if (t.id == updated.id) updated else t,
      ],
    );
  }
}