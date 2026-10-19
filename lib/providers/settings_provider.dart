import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curiosity/models/settings_state.dart';
import 'package:curiosity/services/chat_web_service.dart';

const String _settingsStorageKey = 'curiosity_app_settings';

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier(ref);
  notifier.loadSettings();
  return notifier;
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const SettingsState());

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsStorageKey);
      if (raw != null) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          final loaded = SettingsState.fromJson(decoded);
          state = loaded;
          if (loaded.serverUrl != null && loaded.serverUrl!.isNotEmpty) {
            _ref.read(chatWebServiceProvider).updateServerUrl(loaded.serverUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _persist(SettingsState newState) async {
    state = newState;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsStorageKey, json.encode(newState.toJson()));
    } catch (e) {
      debugPrint('Failed to persist settings: $e');
    }
  }

  // Appearance
  void setAnswerFontSize(double size) => _persist(state.copyWith(answerFontSize: size));
  void setAnswerFont(AnswerFontFamily font) => _persist(state.copyWith(answerFont: font));
  void setAccentColor(AccentColorOption option) => _persist(state.copyWith(accentColor: option));
  void setCompactMode(bool enabled) => _persist(state.copyWith(compactMode: enabled));

  // Search
  void setDefaultFocus(String focus) => _persist(state.copyWith(defaultFocus: focus));
  void setMaxSources(int count) => _persist(state.copyWith(maxSources: count));
  void setShowRelatedQuestions(bool show) => _persist(state.copyWith(showRelatedQuestions: show));
  void setShowSourceCards(bool show) => _persist(state.copyWith(showSourceCards: show));
  void setRememberLastFocus(bool remember) => _persist(state.copyWith(rememberLastFocus: remember));

  // Voice
  void setAutoReadAnswers(bool autoRead) => _persist(state.copyWith(autoReadAnswers: autoRead));
  void setSpeechRate(double rate) => _persist(state.copyWith(speechRate: rate));
  void setSpeechPitch(double pitch) => _persist(state.copyWith(speechPitch: pitch));
  void setTtsVoice(String? voice) => _persist(state.copyWith(ttsVoice: voice));
  void setSpeechLanguage(String? lang) => _persist(state.copyWith(speechLanguage: lang));

  // Data & Privacy
  void setHistoryLimit(int limit) => _persist(state.copyWith(historyLimit: limit));
  void setSaveHistory(bool save) => _persist(state.copyWith(saveHistory: save));

  // Connection
  void setServerUrl(String? url) {
    _persist(state.copyWith(serverUrl: url, clearServerUrl: url == null || url.isEmpty));
    _ref.read(chatWebServiceProvider).updateServerUrl(url);
  }

  // Reset
  Future<void> resetToDefaults() async {
    final defaultSettings = const SettingsState();
    await _persist(defaultSettings);
    _ref.read(chatWebServiceProvider).updateServerUrl(null);
  }
}
