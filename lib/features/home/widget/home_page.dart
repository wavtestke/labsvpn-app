import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/connection/model/connection_status.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/home/widget/connection_button.dart';
import 'package:labsvpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:labsvpn/features/stats/notifier/stats_notifier.dart';
import 'package:labsvpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:labsvpn/utils/number_formatters.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();

    // Stable user ID computed once per session (was DateTime.now() → grew on every rebuild)
    final userId = useMemoized(
      () => 'V${DateTime.now().millisecondsSinceEpoch ~/ 1000 % 1000000000}',
      const [],
    );

    // Safety net: if no profile exists, redirect to intro
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    if (hasAnyProfile.valueOrNull == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/intro');
      });
    }

    final isConnected = connectionStatus.valueOrNull is Connected;
    final isConnecting = connectionStatus.valueOrNull is Connecting || connectionStatus.valueOrNull is Disconnecting;

    return Scaffold(
      backgroundColor: mc.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _TopBar(mc: mc),

            // ── Main scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hint text
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Text(
                        isConnected
                            ? 'Нажмите на кнопку, чтобы отключить VPN'
                            : isConnecting
                                ? 'Устанавливаем защищённое соединение...'
                                : 'Нажмите на кнопку, чтобы включить VPN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isConnected ? mc.green : mc.t2,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Power button + status text
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          const ConnectionButton(),
                          const Gap(16),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isConnected
                                  ? mc.green
                                  : isConnecting
                                      ? mc.accent
                                      : mc.t2,
                            ),
                            child: Text(
                              isConnected
                                  ? 'VPN включён'
                                  : isConnecting
                                      ? 'Подключение...'
                                      : 'VPN отключён',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stats row ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _StatCard(label: 'ПОЛУЧЕНО', value: stats.downlinkTotal.toInt().size(), mc: mc),
                          const Gap(10),
                          _StatCard(label: 'ОТПРАВЛЕНО', value: stats.uplinkTotal.toInt().size(), mc: mc),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // ── User ID row ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: mc.s1,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: mc.b1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ваш ID', style: TextStyle(fontSize: 12, color: mc.t2)),
                            Text(
                              userId,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mc.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar with settings gear icon (matches HTML .topbar) ──
class _TopBar extends StatelessWidget {
  const _TopBar({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: mc.bg.withValues(alpha: 0.94),
        border: Border(bottom: BorderSide(color: mc.b1)),
      ),
      child: Row(
        children: [
          Text(
            'moky',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: mc.text,
            ),
          ),
          Text(
            'vpn',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: mc.accent,
            ),
          ),
          const Spacer(),
          // Settings gear icon (matches HTML .settings-ico)
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: mc.s1,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: mc.b1),
              ),
              child: Icon(Icons.settings_outlined, size: 18, color: mc.t2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card (matches HTML .stat-card) ──
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.mc});
  final String label;
  final String value;
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mc.s1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mc.b1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: mc.t3,
              ),
            ),
            const Gap(6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: mc.text,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox();
}
