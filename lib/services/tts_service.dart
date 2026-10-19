import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

class TtsService {
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<String?> speaking = ValueNotifier(null);

  TtsService() {
    _tts.setCompletionHandler(() => speaking.value = null);
    _tts.setErrorHandler((_) => speaking.value = null);
  }

  String cleanText(String text) {
    var cleaned = text.replaceAll(RegExp(r'\[\d+\]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'`[^`]*`'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[#*_~>]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+[.)]\s*', multiLine: true), '');
    return cleaned.trim();
  }

  Future<void> speak(String text) async {
    if (speaking.value == text) {
      await stop();
      return;
    }
    await stop();
    final plain = cleanText(text);
    if (plain.isEmpty) return;
    try {
      speaking.value = text;
      await _tts.speak(plain);
    } catch (e) {
      speaking.value = null;
      debugPrint('TTS unavailable or failed: $e');
    }
  }

  Future<void> stop() async {
    speaking.value = null;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() {
    _tts.stop();
    speaking.dispose();
  }
}
