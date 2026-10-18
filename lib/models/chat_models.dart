class Source {
  final String title;
  final String url;
  final String snippet;

  const Source({
    required this.title,
    required this.url,
    this.snippet = '',
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'snippet': snippet,
      };
}

enum TurnStatus { searching, generating, done, error }

class Turn {
  final String id;
  final String question;
  final List<Source> sources;
  final String answer;
  final DateTime? startedAt;
  final int? researchedSeconds;
  final List<String> relatedQuestions;
  final String? errorMessage;
  final TurnStatus status;

  const Turn({
    required this.id,
    required this.question,
    this.sources = const [],
    this.answer = '',
    this.relatedQuestions = const [],
    this.startedAt, // new
    this.researchedSeconds, // new
    this.errorMessage,
    this.status = TurnStatus.searching,
  });

  bool get isInFlight =>
      status == TurnStatus.searching || status == TurnStatus.generating;

  Turn copyWith({
    String? id,
    String? question,
    List<Source>? sources,
    String? answer,
    List<String>? relatedQuestions,
    DateTime? startedAt,
    int? researchedSeconds,
    TurnStatus? status,
    String? errorMessage,
  }) {
    return Turn(
      id: id ?? this.id,
      question: question ?? this.question,
      sources: sources ?? this.sources,
      answer: answer ?? this.answer,
      relatedQuestions: relatedQuestions ?? this.relatedQuestions,
      startedAt: startedAt ?? this.startedAt,
      researchedSeconds: researchedSeconds ?? this.researchedSeconds,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'sources': sources.map((s) => s.toJson()).toList(),
        'answer': answer,
        'relatedQuestions': relatedQuestions,
        'startedAt': startedAt?.toIso8601String(),
        'researchedSeconds': researchedSeconds,
        'status': status.name,
        'errorMessage': errorMessage,
      };

  factory Turn.fromJson(Map<String, dynamic> json) {
    return Turn(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      sources: (json['sources'] as List?)
              ?.whereType<Map>()
              .map((s) => Source.fromJson(Map<String, dynamic>.from(s)))
              .toList() ??
          [],
      answer: json['answer']?.toString() ?? '',
      relatedQuestions: (json['relatedQuestions'] as List?)
              ?.map((q) => q.toString())
              .toList() ??
          [],
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      researchedSeconds: json['researchedSeconds'] as int?,
      status: TurnStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TurnStatus.done,
      ),
      errorMessage: json['errorMessage']?.toString(),
    );
  }
}

class ChatThread {
  final String id;
  final String title;
  final List<Turn> turns;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.title,
    required this.turns,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'turns': turns.map((t) => t.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      turns: (json['turns'] as List?)
              ?.whereType<Map>()
              .map((t) => Turn.fromJson(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}