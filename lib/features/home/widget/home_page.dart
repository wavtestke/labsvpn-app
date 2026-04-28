import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/model/constants.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/connection/model/connection_status.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/home/widget/connection_button.dart';
import 'package:labsvpn/features/home/widget/servers_page.dart';
import 'package:labsvpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:labsvpn/features/profile/notifier/profile_notifier.dart';
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

class _TopBar extends HookConsumerWidget {
  const _TopBar({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMenu = useState(false);
    final linkController = useTextEditingController();

    void openManualInput() {
      showMenu.value = false;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ManualInputSheet(mc: mc, ref: ref),
      );
    }

    Future<void> pasteFromClipboard() async {
      showMenu.value = false;
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text?.trim() ?? '';
      if (text.isEmpty || !context.mounted) return;
      _addProfile(context, ref, text, mc);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
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
                onTap: () => showMenu.value = !showMenu.value,
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
        ),
        // Dropdown menu
        if (showMenu.value)
          Positioned(
            top: 56,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 210,
                  decoration: BoxDecoration(
                    color: mc.s1,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MenuItem(
                        icon: Icons.edit_outlined,
                        label: 'Ввести вручную',
                        mc: mc,
                        onTap: openManualInput,
                        showBorder: false,
                      ),
                      _MenuItem(
                        icon: Icons.content_paste_outlined,
                        label: 'Добавить из буфера',
                        mc: mc,
                        onTap: pasteFromClipboard,
                        showBorder: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Overlay to close menu
        if (showMenu.value)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => showMenu.value = false,
            ),
          ),
      ],
    );
  }
}

void _addProfile(BuildContext context, WidgetRef ref, String link, MokyThemeData mc) async {
  try {
    await ref.read(addProfileNotifierProvider.notifier).addClipboard(link);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Конфигурация добавлена'),
          backgroundColor: mc.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ManualInputSheet extends ConsumerWidget {
  const _ManualInputSheet({required this.mc, required this.ref});
  final MokyThemeData mc;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final controller = TextEditingController();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: mc.s1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: mc.s3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ввести ссылку',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: mc.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: mc.text),
              decoration: InputDecoration(
                hintText: 'vless://...',
                hintStyle: TextStyle(color: mc.t3),
                filled: true,
                fillColor: mc.s2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mc.b1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mc.b1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mc.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(context);
                  _addProfile(context, ref, text, mc);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mc.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Подключить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.mc,
    required this.onTap,
    required this.showBorder,
  });
  final IconData icon;
  final String label;
  final MokyThemeData mc;
  final VoidCallback onTap;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: showBorder
            ? BoxDecoration(border: Border(top: BorderSide(color: mc.s2)))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: mc.t2),
            const Gap(10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: mc.text,
              ),
            ),
          ],
        ),
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
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const GeoBottomSheet(),
        );
      },
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
                  Text('32 ms', style: TextStyle(fontSize: 12, color: mc.t3)),
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
              style: TextStyle(fontSize: 10, color: mc.t3, letterSpacing: 0.5),
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
