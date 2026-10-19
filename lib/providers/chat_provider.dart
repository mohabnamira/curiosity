import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/services/chat_web_service.dart';

final chatNotifierProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatState {
  final List<ChatThread> savedThreads;
  final String? activeThreadId;
  final List<Turn> turns;
  final String? activeTurnId;
  final int? highlightedSourceIndex;
  final String focus;

  const ChatState({
    this.savedThreads = const [],
    this.activeThreadId,
    this.turns = const [],
    this.activeTurnId,
    this.highlightedSourceIndex,
    this.focus = 'all',
  });

  Turn? get activeTurn {
    if (activeTurnId == null) return null;
    for (final t in turns) {
      if (t.id == activeTurnId) return t;
    }
    return null;
  }

  ChatState copyWith({
    List<ChatThread>? savedThreads,
    String? activeThreadId,
    List<Turn>? turns,
    String? activeTurnId,
    int? highlightedSourceIndex,
    String? focus,
    bool clearActiveThread = false,
    bool clearHighlight = false,
  }) {
    return ChatState(
      savedThreads: savedThreads ?? this.savedThreads,
      activeThreadId: clearActiveThread
          ? null
          : (activeThreadId ?? this.activeThreadId),
      turns: turns ?? this.turns,
      activeTurnId: activeTurnId ?? this.activeTurnId,
      highlightedSourceIndex: clearHighlight
          ? null
          : (highlightedSourceIndex ?? this.highlightedSourceIndex),
      focus: focus ?? this.focus,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  static const String _storageKey = 'curiosity_chat_threads_v1';
  static const int _maxHistoryTurns = 3;

  static const int _maxThreads = 50;

  final Set<String> _cancelledTurnIds = {};
  final Set<String> _liveTurnIds = {};

  bool isLiveTurn(String id) => _liveTurnIds.contains(id);

  // TODO(backend): server keeps streaming until cancel support exists
  void cancelTurn(String id) {
    _cancelledTurnIds.add(id);
    final turn = _findTurn(id);
    if (turn != null && turn.isInFlight) {
      final updated = turn.copyWith(status: TurnStatus.done);
      _replaceTurn(updated);
      _persistCurrentConversation();
    }
  }

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

    _loadThreads();

    return const ChatState();
  }

  Future<void> _loadThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_storageKey);
      if (raw != null) {
        final threads = raw
            .map((str) => ChatThread.fromJson(json.decode(str)))
            .toList();
        threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        state = state.copyWith(savedThreads: threads);
      }
    } catch (_) {}
  }

  Future<void> _saveThreads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = state.savedThreads
          .map((thread) => json.encode(thread.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, raw);
    } catch (_) {}
  }

  void startNewChat() {
    state = state.copyWith(
      turns: [],
      activeTurnId: null,
      clearActiveThread: true,
      clearHighlight: true,
    );
  }

  void loadThread(String threadId) {
    final thread = state.savedThreads.firstWhere(
      (t) => t.id == threadId,
      orElse: () => ChatThread(id: '', title: '', turns: [], updatedAt: DateTime.now()),
    );
    if (thread.id.isEmpty) return;

    state = state.copyWith(
      activeThreadId: thread.id,
      turns: thread.turns,
      activeTurnId: thread.turns.isNotEmpty ? thread.turns.last.id : null,
      clearHighlight: true,
    );
  }

  Future<void> deleteThread(String threadId) async {
    final updated = state.savedThreads.where((t) => t.id != threadId).toList();
    state = state.copyWith(savedThreads: updated);
    await _saveThreads();
    if (state.activeThreadId == threadId) {
      startNewChat();
    }
  }

  Future<void> renameThread(String id, String title) async {
    final updated = state.savedThreads.map((thread) {
      if (thread.id == id) {
        return ChatThread(
          id: thread.id,
          title: title,
          turns: thread.turns,
          updatedAt: thread.updatedAt,
        );
      }
      return thread;
    }).toList();
    state = state.copyWith(savedThreads: updated);
    await _saveThreads();
  }

  void setFocus(String focus) {
    state = state.copyWith(focus: focus);
  }

  String sendQuery(String query) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _liveTurnIds.add(id);

    final finished = state.turns
        .where((t) => t.status == TurnStatus.done && t.answer.isNotEmpty)
        .toList();
    final recent = finished.length > _maxHistoryTurns
        ? finished.sublist(finished.length - _maxHistoryTurns)
        : finished;
    final history = recent
        .map((t) => {'question': t.question, 'answer': t.answer})
        .toList();

    state = state.copyWith(
      turns: [
        ...state.turns,
        Turn(id: id, question: query, startedAt: DateTime.now()),
      ],
      activeTurnId: id,
      clearHighlight: true,
    );

    ref.read(chatWebServiceProvider).sendChat(id, query, history, state.focus).catchError((_) {
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
    if (_cancelledTurnIds.contains(id)) return;

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

          int? researchedSeconds;
          if (turn.startedAt != null) {
            final diff = DateTime.now().difference(turn.startedAt!).inSeconds;
            researchedSeconds = diff < 1 ? 1 : diff;
          }

          updated = turn.copyWith(
            sources: sources,
            researchedSeconds: researchedSeconds,
            status: TurnStatus.generating,
          );
        }
      case 'content':
        updated = turn.copyWith(
          answer: turn.answer + (data['data']?.toString() ?? ''),
          status: TurnStatus.generating,
        );
      case 'related':
        final rawQuestions = data['data'];
        if (rawQuestions is List) {
          final questions = rawQuestions.whereType<String>().toList();
          updated = turn.copyWith(relatedQuestions: questions);
        }
      case 'done':
        updated = turn.copyWith(status: TurnStatus.done);
      case 'error':
        updated = turn.copyWith(
          status: TurnStatus.error,
          errorMessage: data['data']?.toString() ?? 'Unknown error',
        );
    }

    if (updated != null) {
      _replaceTurn(updated);
      if (updated.status == TurnStatus.done) {
        _persistCurrentConversation();
      }
    }
  }

  void _persistCurrentConversation() {
    final finished = state.turns.where((t) => !t.isInFlight).toList();
    if (finished.isEmpty) return;
    final title = finished.first.question;

    final threadId = state.activeThreadId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final thread = ChatThread(
      id: threadId,
      title: title,
      turns: finished,
      updatedAt: DateTime.now(),
    );

    final others = state.savedThreads.where((t) => t.id != threadId);
    final updatedThreads = [thread, ...others]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = state.copyWith(
      savedThreads: updatedThreads.take(_maxThreads).toList(),
      activeThreadId: threadId,
    );
    _saveThreads();
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