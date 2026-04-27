import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/model/constants.dart';
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
import 'package:url_launcher/url_launcher.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final stats = ref.watch(statsNotifierProvider).asData?.value ?? SystemInfo.create();

    // Redirect to intro if no profile
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    if (hasAnyProfile.valueOrNull == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/intro');
      });
    }

    final isConnected = connectionStatus.valueOrNull is Connected;
    final isConnecting = connectionStatus.valueOrNull is Connecting ||
        connectionStatus.valueOrNull is Disconnecting;

    return Scaffold(
      backgroundColor: mc.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(mc: mc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Gap(32),

                    // Status text
                    Text(
                      isConnected
                          ? 'Подключено'
                          : isConnecting
                              ? 'Подключение...'
                              : 'Не подключено',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: mc.text,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      isConnected
                          ? 'VLESS Reality'
                          : isConnecting
                              ? 'Устанавливаем соединение'
                              : 'Нажмите для подключения',
                      style: TextStyle(fontSize: 13, color: mc.t3),
                    ),
                    const Gap(32),

                    // Power button
                    const ConnectionButton(),
                    const Gap(32),

                    // Server card
                    _ServerCard(mc: mc),
                    const Gap(12),

                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          label: 'Скачано',
                          value: stats.downlinkTotal.toInt().size(),
                          mc: mc,
                        ),
                        const Gap(12),
                        _StatCard(
                          label: 'Отправлено',
                          value: stats.uplinkTotal.toInt().size(),
                          mc: mc,
                        ),
                      ],
                    ),
                    const Gap(24),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Telegram icon
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(Constants.telegramBotUrl)),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mc.s1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.telegram, size: 22, color: mc.t2),
            ),
          ),
          const Spacer(),
          // App name
          Text(
            'LabsVpn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: mc.text,
            ),
          ),
          const Spacer(),
          // Plus button
          GestureDetector(
            onTap: () => context.go('/intro'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: mc.s1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add, size: 22, color: mc.t2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerCard extends ConsumerWidget {
  const _ServerCard({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.go('/servers'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: mc.s1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🇳🇱', style: TextStyle(fontSize: 22)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Netherlands',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: mc.text,
                    ),
                  ),
                  Text(
                    '32 ms',
                    style: TextStyle(fontSize: 12, color: mc.t3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: mc.t3),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.mc});
  final String label;
  final String value;
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mc.s1,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: mc.text,
              ),
            ),
            const Gap(3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: mc.t3,
                letterSpacing: 0.5,
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
