class Source {
  final String title;
  final String url;

  const Source({required this.title, required this.url});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

enum TurnStatus { searching, generating, done, error }

class Turn {
  final String id;
  final String question;
  final List<Source> sources;
  final String answer;
  final TurnStatus status;
  final String? errorMessage;

  const Turn({
    required this.id,
    required this.question,
    this.sources = const [],
    this.answer = '',
    this.status = TurnStatus.searching,
    this.errorMessage,
  });

  /// True while the server can still send us events for this turn.
  bool get isInFlight =>
      status == TurnStatus.searching || status == TurnStatus.generating;

  Turn copyWith({
    String? id,
    String? question,
    List<Source>? sources,
    String? answer,
    TurnStatus? status,
    String? errorMessage,
  }) {
    return Turn(
      id: id ?? this.id,
      question: question ?? this.question,
      sources: sources ?? this.sources,
      answer: answer ?? this.answer,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}