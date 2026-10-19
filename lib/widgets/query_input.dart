import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/services/tts_service.dart';
import 'package:curiosity/theme/colors.dart';

class QueryInput extends ConsumerStatefulWidget {
  final String hintText;
  final ValueChanged<String>? onSubmit;
  final bool autofocus;

  const QueryInput({
    super.key,
    required this.hintText,
    this.onSubmit,
    this.autofocus = false,
  });

  @override
  ConsumerState<QueryInput> createState() => _QueryInputState();
}

class _QueryInputState extends ConsumerState<QueryInput>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _pulseController;

  bool _isFocused = false;
  bool _isListening = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  void _onFocusChanged() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  void _setListening(bool value) {
    if (mounted) setState(() => _isListening = value);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    _speech.stop();
    _setListening(false);
    ref.read(ttsServiceProvider).stop();

    _controller.clear();
    setState(() => _hasText = false);

    if (widget.onSubmit != null) {
      widget.onSubmit!(query);
    } else {
      ref.read(chatNotifierProvider.notifier).sendQuery(query);
    }
  }

  void _stopGenerating(String? inFlightTurnId) {
    if (inFlightTurnId != null) {
      ref.read(chatNotifierProvider.notifier).cancelTurn(inFlightTurnId);
    }
  }

  Future<void> _listen() async {
    if (_isListening) {
      await _speech.stop();
      _setListening(false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (_) => _setListening(false),
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            _setListening(false);
          }
        },
      );

      if (!available) {
        _showSnack('Voice input is unavailable. Allow the microphone, or use Chrome.');
        _setListening(false);
        return;
      }

      _setListening(true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          }
        },
      );
    } catch (_) {
      _showSnack('Voice input is not supported on this platform.');
      _setListening(false);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        // Shift+Enter creates a newline
        return KeyEventResult.ignored;
      } else {
        // Enter sends query
        _submit();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final inFlightTurn = chatState.turns.cast<dynamic>().firstWhere(
          (t) => t.isInFlight,
          orElse: () => null,
        );
    final isInFlight = inFlightTurn != null;

    if (isInFlight) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }

    final currentFocus = chatState.focus;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final List<BoxShadow> shadows;
          if (isInFlight) {
            final alpha = 0.04 + 0.06 * _pulseController.value;
            shadows = [
              BoxShadow(
                color: Colors.white.withValues(alpha: alpha),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ];
          } else if (_isFocused) {
            shadows = [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.07),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ];
          } else {
            shadows = const [];
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              boxShadow: shadows,
            ),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top multiline textarea
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                minLines: 1,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _isListening ? 'Listening...' : widget.hintText,
                  hintStyle: GoogleFonts.inter(
                    color: _isListening ? Colors.redAccent : AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            // Bottom action row
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  // Attach button (UI-only)
                  _buildAttachButton(),
                  const SizedBox(width: 6),
                  // Focus pill dropdown
                  _buildFocusPill(currentFocus),
                  const Spacer(),
                  // Mic button
                  _buildMicButton(),
                  const SizedBox(width: 8),
                  // Send / Stop button
                  _buildSubmitOrStopButton(isInFlight, inFlightTurn?.id as String?),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButton() {
    // TODO(backend): file attachment not supported on backend yet
    return Tooltip(
      message: 'Attach (Coming soon)',
      child: InkWell(
        onTap: () => _showSnack('Attach file is coming soon!'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.iconMuted),
              SizedBox(width: 4),
              Text(
                'Attach',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusPill(String currentFocus) {
    // TODO(backend): filter Tavily by domains per focus
    final (label, icon) = switch (currentFocus) {
      'academic' => ('Academic', Icons.school_outlined),
      'youtube' => ('YouTube', Icons.play_circle_outline_rounded),
      _ => ('All', Icons.language_rounded),
    };

    return PopupMenuButton<String>(
      tooltip: 'Focus mode',
      offset: const Offset(0, 36),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      onSelected: (mode) {
        ref.read(chatNotifierProvider.notifier).setFocus(mode);
      },
      itemBuilder: (context) => [
        _buildPopupItem('all', 'All', Icons.language_rounded, currentFocus == 'all'),
        _buildPopupItem('academic', 'Academic', Icons.school_outlined, currentFocus == 'academic'),
        _buildPopupItem('youtube', 'YouTube', Icons.play_circle_outline_rounded, currentFocus == 'youtube'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.iconMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.iconMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.textPrimary : AppColors.iconMuted,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return Tooltip(
      message: _isListening ? 'Stop listening' : 'Voice input',
      child: InkWell(
        onTap: _listen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none_rounded,
            size: 18,
            color: _isListening ? Colors.redAccent : AppColors.iconMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitOrStopButton(bool isInFlight, String? inFlightTurnId) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: isInFlight
          ? Tooltip(
              key: const ValueKey('stop_button'),
              message: 'Stop generating',
              child: InkWell(
                onTap: () => _stopGenerating(inFlightTurnId),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.focus,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.stop_rounded,
                      size: 16,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            )
          : Tooltip(
              key: const ValueKey('submit_button'),
              message: _hasText ? 'Send' : '',
              child: InkWell(
                onTap: _hasText ? _submit : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _hasText ? AppColors.focus : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 17,
                      color: _hasText ? AppColors.background : AppColors.iconMuted,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
