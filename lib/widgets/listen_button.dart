import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/services/tts_service.dart';
import 'package:curiosity/theme/colors.dart';

class ListenButton extends ConsumerWidget {
  final String text;

  const ListenButton({super.key, required this.text});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tts = ref.watch(ttsServiceProvider);
    return ValueListenableBuilder<String?>(
      valueListenable: tts.speaking,
      builder: (context, speaking, _) {
        final playing = speaking == text;
        return IconButton(
          icon: Icon(
            playing ? Icons.stop_rounded : Icons.volume_up_rounded,
            size: 18,
            color: AppColors.iconMuted,
          ),
          tooltip: playing ? 'Stop listening' : 'Listen to answer',
          onPressed: () => tts.speak(text),
        );
      },
    );
  }
}
