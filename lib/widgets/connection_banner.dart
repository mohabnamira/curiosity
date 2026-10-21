import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/services/chat_web_service.dart';
import 'package:curiosity/theme/colors.dart';

/// Floating gray toast with drop shadow that appears at the top when disconnected
/// or reconnecting to the server, and disappears smoothly when connected.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webService = ref.watch(chatWebServiceProvider);

    return ValueListenableBuilder<ConnectionStatus>(
      valueListenable: webService.status,
      builder: (context, status, _) {
        final isConnected = status == ConnectionStatus.connected;
        final isReconnecting = status == ConnectionStatus.reconnecting ||
            status == ConnectionStatus.connecting;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: isConnected
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2129),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2E323D),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isReconnecting)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 14,
                              color: AppColors.iconMuted,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            isReconnecting
                                ? 'Reconnecting to server...'
                                : 'Connection lost',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!isReconnecting) ...[
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => webService.connect(),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2E38),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
