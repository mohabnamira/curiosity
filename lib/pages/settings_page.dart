import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/settings_state.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/services/chat_web_service.dart';
import 'package:curiosity/services/export_service.dart' as export_service;
import 'package:curiosity/services/tts_service.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/settings_tiles.dart';
import 'package:curiosity/widgets/side_bar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _serverUrlController;
  bool _testingConnection = false;
  String? _connectionTestResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _serverUrlController = TextEditingController(text: settings.serverUrl ?? '');
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionTestResult = null;
    });

    final url = _serverUrlController.text.trim();
    ref.read(settingsNotifierProvider.notifier).setServerUrl(url.isEmpty ? null : url);

    await Future.delayed(const Duration(milliseconds: 1500));
    final status = ref.read(chatWebServiceProvider).status.value;

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _connectionTestResult = status == ConnectionStatus.connected
            ? 'Connected successfully!'
            : 'Status: ${status.name}';
      });
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear all conversations',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete all conversation history? This action cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(chatNotifierProvider.notifier).clearAllHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All history cleared.')),
        );
      }
    }
  }

  void _exportAllJson() {
    final threads = ref.read(chatNotifierProvider).savedThreads;
    if (threads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No conversations to export.')),
      );
      return;
    }
    final rawJson = const JsonEncoder.withIndent('  ').convert(
      threads.map((t) => t.toJson()).toList(),
    );
    // Export using active turn stub or share JSON
    if (threads.isNotEmpty && threads.first.turns.isNotEmpty) {
      final exportTurn = threads.first.turns.first.copyWith(
        question: 'Curiosity Full Export (${threads.length} conversations)',
        answer: rawJson,
      );
      export_service.exportMarkdown(context, exportTurn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          if (isDesktop) const SideBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 48),
                  children: [
                    // 1. APPEARANCE
                    const SettingSectionHeader(
                      title: 'Appearance',
                      icon: Icons.palette_outlined,
                    ),
                    SettingCard(
                      children: [
                        SettingSliderTile(
                          title: 'Answer Font Size',
                          value: settings.answerFontSize,
                          min: 13.0,
                          max: 22.0,
                          divisions: 9,
                          valueLabel: '${settings.answerFontSize.toInt()} px',
                          onChanged: settingsNotifier.setAnswerFontSize,
                        ),
                        SettingTile(
                          title: 'Answer Typography',
                          subtitle: 'Font style for generated answers',
                          trailing: DropdownButton<AnswerFontFamily>(
                            value: settings.answerFont,
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconMuted),
                            items: AnswerFontFamily.values.map((f) {
                              return DropdownMenuItem(
                                value: f,
                                child: Text(f.label, style: const TextStyle(color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (fam) {
                              if (fam != null) settingsNotifier.setAnswerFont(fam);
                            },
                          ),
                        ),
                        SettingTile(
                          title: 'Accent Color',
                          subtitle: settings.accentColor.label,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: AccentColorOption.values.map((opt) {
                              final isSelected = opt == settings.accentColor;
                              return GestureDetector(
                                onTap: () => settingsNotifier.setAccentColor(opt),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: opt.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: opt.color.withValues(alpha: 0.6),
                                              blurRadius: 6,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SettingTile(
                          title: 'Compact Mode',
                          subtitle: 'Reduces padding between chat elements',
                          trailing: Switch(
                            value: settings.compactMode,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setCompactMode,
                          ),
                        ),
                      ],
                    ),

                    // 2. SEARCH
                    const SettingSectionHeader(
                      title: 'Search & Sources',
                      icon: Icons.search_rounded,
                    ),
                    SettingCard(
                      children: [
                        SettingTile(
                          title: 'Default Focus Mode',
                          subtitle: 'Mode used when launching new queries',
                          trailing: DropdownButton<String>(
                            value: settings.defaultFocus,
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconMuted),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 'academic', child: Text('Academic', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 'youtube', child: Text('YouTube', style: TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (val) {
                              if (val != null) settingsNotifier.setDefaultFocus(val);
                            },
                          ),
                        ),
                        SettingTile(
                          title: 'Number of Sources',
                          subtitle: 'Web sources queried per search turn',
                          trailing: DropdownButton<int>(
                            value: settings.maxSources,
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconMuted),
                            items: const [
                              DropdownMenuItem(value: 3, child: Text('3 Sources', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 5, child: Text('5 Sources', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 8, child: Text('8 Sources', style: TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (count) {
                              if (count != null) settingsNotifier.setMaxSources(count);
                            },
                          ),
                        ),
                        SettingTile(
                          title: 'Show Source Cards',
                          subtitle: 'Display sources pill and right panel',
                          trailing: Switch(
                            value: settings.showSourceCards,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setShowSourceCards,
                          ),
                        ),
                        SettingTile(
                          title: 'Show Related Questions',
                          subtitle: 'Display AI suggested follow-ups after an answer',
                          trailing: Switch(
                            value: settings.showRelatedQuestions,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setShowRelatedQuestions,
                          ),
                        ),
                        SettingTile(
                          title: 'Remember Last Focus',
                          subtitle: 'Keep focus mode selected across queries',
                          trailing: Switch(
                            value: settings.rememberLastFocus,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setRememberLastFocus,
                          ),
                        ),
                      ],
                    ),

                    // 3. VOICE & AUDIO
                    const SettingSectionHeader(
                      title: 'Voice & Audio',
                      icon: Icons.volume_up_outlined,
                    ),
                    SettingCard(
                      children: [
                        SettingTile(
                          title: 'Auto-Read Answers',
                          subtitle: 'Speak generated answer aloud when finished',
                          trailing: Switch(
                            value: settings.autoReadAnswers,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setAutoReadAnswers,
                          ),
                        ),
                        SettingSliderTile(
                          title: 'Speech Rate',
                          value: settings.speechRate,
                          min: 0.3,
                          max: 1.0,
                          divisions: 7,
                          valueLabel: '${(settings.speechRate * 10).round() / 10}x',
                          onChanged: settingsNotifier.setSpeechRate,
                        ),
                        SettingSliderTile(
                          title: 'Speech Pitch',
                          value: settings.speechPitch,
                          min: 0.5,
                          max: 1.5,
                          divisions: 10,
                          valueLabel: '${(settings.speechPitch * 10).round() / 10}x',
                          onChanged: settingsNotifier.setSpeechPitch,
                        ),
                        SettingTile(
                          title: 'Test Speech Output',
                          subtitle: 'Preview audio with current rate and pitch',
                          trailing: TextButton(
                            onPressed: () {
                              ref.read(ttsServiceProvider).speak(
                                    'Curiosity is an AI-powered conversational search engine.',
                                  );
                            },
                            child: const Text('Preview', style: TextStyle(color: AppColors.textPrimary)),
                          ),
                        ),
                      ],
                    ),

                    // 4. DATA & PRIVACY
                    const SettingSectionHeader(
                      title: 'Data & Privacy',
                      icon: Icons.security_rounded,
                    ),
                    SettingCard(
                      children: [
                        SettingTile(
                          title: 'Save History',
                          subtitle: 'Store conversations locally in sidebar',
                          trailing: Switch(
                            value: settings.saveHistory,
                            activeTrackColor: AppColors.focus,
                            onChanged: settingsNotifier.setSaveHistory,
                          ),
                        ),
                        SettingTile(
                          title: 'History Limit',
                          subtitle: 'Max conversation threads stored',
                          trailing: DropdownButton<int>(
                            value: settings.historyLimit,
                            dropdownColor: AppColors.surface,
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconMuted),
                            items: const [
                              DropdownMenuItem(value: 10, child: Text('10 threads', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 25, child: Text('25 threads', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 50, child: Text('50 threads', style: TextStyle(color: AppColors.textPrimary))),
                              DropdownMenuItem(value: 100, child: Text('100 threads', style: TextStyle(color: AppColors.textPrimary))),
                            ],
                            onChanged: (lim) {
                              if (lim != null) settingsNotifier.setHistoryLimit(lim);
                            },
                          ),
                        ),
                        SettingTile(
                          title: 'Export Conversations',
                          subtitle: 'Export stored chat history as structured data',
                          trailing: TextButton(
                            onPressed: _exportAllJson,
                            child: const Text('Export', style: TextStyle(color: AppColors.textPrimary)),
                          ),
                        ),
                        SettingTile(
                          title: 'Clear All History',
                          subtitle: 'Permanently remove all saved conversations',
                          trailing: TextButton(
                            onPressed: _confirmClearHistory,
                            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      ],
                    ),

                    // 5. CONNECTION
                    const SettingSectionHeader(
                      title: 'Connection',
                      icon: Icons.wifi_rounded,
                    ),
                    SettingCard(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Server URL',
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _serverUrlController,
                                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: defaultServerUrl,
                                  hintStyle: GoogleFonts.inter(color: AppColors.iconMuted, fontSize: 13),
                                  filled: true,
                                  fillColor: const Color(0xFF1F2128),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ValueListenableBuilder<ConnectionStatus>(
                                    valueListenable: ref.read(chatWebServiceProvider).status,
                                    builder: (context, status, _) {
                                      final isConn = status == ConnectionStatus.connected;
                                      return Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isConn ? Colors.greenAccent : Colors.amberAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            status.name.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: _testingConnection ? null : _testConnection,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.border),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: _testingConnection
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.focus),
                                          )
                                        : const Text('Test & Save', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                  ),
                                ],
                              ),
                              if (_connectionTestResult != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _connectionTestResult!,
                                  style: GoogleFonts.inter(
                                    color: _connectionTestResult!.contains('success') ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 6. ABOUT
                    const SettingSectionHeader(
                      title: 'About',
                      icon: Icons.info_outline_rounded,
                    ),
                    SettingCard(
                      children: [
                        const SettingTile(
                          title: 'Version',
                          trailing: Text('0.1.0+1', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ),
                        SettingTile(
                          title: 'Open Source Licenses',
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.iconMuted),
                          onTap: () => showLicensePage(
                            context: context,
                            applicationName: 'Curiosity',
                            applicationVersion: '0.1.0',
                          ),
                        ),
                        SettingTile(
                          title: 'Reset All Settings',
                          subtitle: 'Revert settings to initial defaults',
                          trailing: TextButton(
                            onPressed: () async {
                              await settingsNotifier.resetToDefaults();
                              _serverUrlController.clear();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Settings reset to defaults.')),
                                );
                              }
                            },
                            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
