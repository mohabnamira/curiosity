import 'package:flutter/material.dart';

/// Supported answer font families
enum AnswerFontFamily {
  serif('Serif (Newsreader)'),
  sans('Sans (Inter)'),
  mono('Mono (Fira Code)');

  final String label;
  const AnswerFontFamily(this.label);
}

/// Accent color options
enum AccentColorOption {
  monochrome('White / Monochrome', Color(0xFFFFFFFF)),
  blue('Electric Blue', Color(0xFF3B82F6)),
  emerald('Emerald', Color(0xFF10B981)),
  purple('Violet', Color(0xFF8B5CF6)),
  amber('Amber', Color(0xFFF59E0B));

  final String label;
  final Color color;
  const AccentColorOption(this.label, this.color);
}

/// Immutable state containing all customizable user preferences.
class SettingsState {
  // Appearance
  final double answerFontSize; // 13.0 to 22.0, default 17.0
  final AnswerFontFamily answerFont;
  final AccentColorOption accentColor;
  final bool compactMode;

  // Search
  final String defaultFocus; // 'all' | 'academic' | 'youtube'
  final int maxSources; // 3 | 5 | 8
  final bool showRelatedQuestions;
  final bool showSourceCards;
  final bool rememberLastFocus;

  // Voice
  final bool autoReadAnswers;
  final double speechRate; // 0.3 to 1.0, default 0.5
  final double speechPitch; // 0.5 to 1.5, default 1.0
  final String? ttsVoice;
  final String? speechLanguage;

  // Data & Privacy
  final int historyLimit; // 10 | 25 | 50 | 100
  final bool saveHistory;

  // Connection
  final String? serverUrl;

  const SettingsState({
    this.answerFontSize = 17.0,
    this.answerFont = AnswerFontFamily.serif,
    this.accentColor = AccentColorOption.monochrome,
    this.compactMode = false,
    this.defaultFocus = 'all',
    this.maxSources = 5,
    this.showRelatedQuestions = true,
    this.showSourceCards = true,
    this.rememberLastFocus = true,
    this.autoReadAnswers = false,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.ttsVoice,
    this.speechLanguage,
    this.historyLimit = 50,
    this.saveHistory = true,
    this.serverUrl,
  });

  SettingsState copyWith({
    double? answerFontSize,
    AnswerFontFamily? answerFont,
    AccentColorOption? accentColor,
    bool? compactMode,
    String? defaultFocus,
    int? maxSources,
    bool? showRelatedQuestions,
    bool? showSourceCards,
    bool? rememberLastFocus,
    bool? autoReadAnswers,
    double? speechRate,
    double? speechPitch,
    String? ttsVoice,
    String? speechLanguage,
    int? historyLimit,
    bool? saveHistory,
    String? serverUrl,
    bool clearServerUrl = false,
  }) {
    return SettingsState(
      answerFontSize: answerFontSize ?? this.answerFontSize,
      answerFont: answerFont ?? this.answerFont,
      accentColor: accentColor ?? this.accentColor,
      compactMode: compactMode ?? this.compactMode,
      defaultFocus: defaultFocus ?? this.defaultFocus,
      maxSources: maxSources ?? this.maxSources,
      showRelatedQuestions: showRelatedQuestions ?? this.showRelatedQuestions,
      showSourceCards: showSourceCards ?? this.showSourceCards,
      rememberLastFocus: rememberLastFocus ?? this.rememberLastFocus,
      autoReadAnswers: autoReadAnswers ?? this.autoReadAnswers,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      speechLanguage: speechLanguage ?? this.speechLanguage,
      historyLimit: historyLimit ?? this.historyLimit,
      saveHistory: saveHistory ?? this.saveHistory,
      serverUrl: clearServerUrl ? null : (serverUrl ?? this.serverUrl),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answerFontSize': answerFontSize,
      'answerFont': answerFont.name,
      'accentColor': accentColor.name,
      'compactMode': compactMode,
      'defaultFocus': defaultFocus,
      'maxSources': maxSources,
      'showRelatedQuestions': showRelatedQuestions,
      'showSourceCards': showSourceCards,
      'rememberLastFocus': rememberLastFocus,
      'autoReadAnswers': autoReadAnswers,
      'speechRate': speechRate,
      'speechPitch': speechPitch,
      'ttsVoice': ttsVoice,
      'speechLanguage': speechLanguage,
      'historyLimit': historyLimit,
      'saveHistory': saveHistory,
      'serverUrl': serverUrl,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      answerFontSize: (json['answerFontSize'] as num?)?.toDouble() ?? 17.0,
      answerFont: AnswerFontFamily.values.firstWhere(
        (e) => e.name == json['answerFont'],
        orElse: () => AnswerFontFamily.serif,
      ),
      accentColor: AccentColorOption.values.firstWhere(
        (e) => e.name == json['accentColor'],
        orElse: () => AccentColorOption.monochrome,
      ),
      compactMode: json['compactMode'] as bool? ?? false,
      defaultFocus: json['defaultFocus'] as String? ?? 'all',
      maxSources: json['maxSources'] as int? ?? 5,
      showRelatedQuestions: json['showRelatedQuestions'] as bool? ?? true,
      showSourceCards: json['showSourceCards'] as bool? ?? true,
      rememberLastFocus: json['rememberLastFocus'] as bool? ?? true,
      autoReadAnswers: json['autoReadAnswers'] as bool? ?? false,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      speechPitch: (json['speechPitch'] as num?)?.toDouble() ?? 1.0,
      ttsVoice: json['ttsVoice'] as String?,
      speechLanguage: json['speechLanguage'] as String?,
      historyLimit: json['historyLimit'] as int? ?? 50,
      saveHistory: json['saveHistory'] as bool? ?? true,
      serverUrl: json['serverUrl'] as String?,
    );
  }
}
