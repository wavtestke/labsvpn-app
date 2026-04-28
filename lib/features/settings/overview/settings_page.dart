import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/model/constants.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/core/theme/app_theme_mode.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/core/theme/theme_preferences.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/profile/data/profile_data_providers.dart';
import 'package:labsvpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final isDark = mc.isDark;
    final autoConnect = useState(false);
    final notifications = useState(true);
    final version = useState('1.0.0');

    useEffect(() {
      SharedPreferences.getInstance().then((prefs) {
        autoConnect.value = prefs.getBool('auto_connect') ?? false;
        notifications.value = prefs.getBool('notifications') ?? true;
      });
      PackageInfo.fromPlatform().then((info) {
        version.value = info.version;
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: mc.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const Gap(24),
            Text(
              'Настройки',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: mc.text,
              ),
            ),
            const Gap(20),

            // Group 1: theme, protocol, dns
            _SettingsGroup(
              mc: mc,
              children: [
                _SettingsItem(
                  mc: mc,
                  icon: Icons.dark_mode_outlined,
                  title: 'Тёмная тема',
                  trailing: _Toggle(
                    value: isDark,
                    mc: mc,
                    onChanged: (_) {
                      ref.read(themePreferencesProvider.notifier).changeThemeMode(
                        isDark ? AppThemeMode.light : AppThemeMode.dark,
                      );
                    },
                  ),
                ),
                _SettingsItem(
                  mc: mc,
                  icon: Icons.security_outlined,
                  title: 'Протокол',
                  value: 'VLESS Reality',
                ),
                _SettingsItem(
                  mc: mc,
                  icon: Icons.language_outlined,
                  title: 'DNS',
                  value: 'Авто',
                ),
              ],
            ),
            const Gap(8),

            // Group 2: auto-connect, notifications
            _SettingsGroup(
              mc: mc,
              children: [
                _SettingsItem(
                  mc: mc,
                  icon: Icons.auto_mode_outlined,
                  title: 'Автоподключение',
                  trailing: _Toggle(
                    value: autoConnect.value,
                    mc: mc,
                    onChanged: (val) async {
                      autoConnect.value = val;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('auto_connect', val);
                    },
                  ),
                ),
                _SettingsItem(
                  mc: mc,
                  icon: Icons.notifications_outlined,
                  title: 'Уведомления',
                  trailing: _Toggle(
                    value: notifications.value,
                    mc: mc,
                    onChanged: (val) async {
                      notifications.value = val;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications', val);
                    },
                  ),
                ),
              ],
            ),
            const Gap(8),

            // Group 3: about
            _SettingsGroup(
              mc: mc,
              children: [
                _SettingsItem(
                  mc: mc,
                  icon: Icons.info_outline,
                  title: 'О приложении',
                  value: 'v${version.value}',
                  showArrow: true,
                  onTap: () => context.goNamed('about'),
                ),
              ],
            ),
            const Gap(8),

            // Group 4: support, reset
            _SettingsGroup(
              mc: mc,
              children: [
                _SettingsItem(
                  mc: mc,
                  icon: Icons.support_agent_outlined,
                  title: 'Написать в поддержку',
                  showArrow: true,
                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.supportUrl)),
                ),
                _SettingsItem(
                  mc: mc,
                  icon: Icons.delete_outline,
                  title: 'Сбросить конфигурацию',
                  titleColor: mc.red,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: mc.s1,
                        title: Text('Сбросить?', style: TextStyle(color: mc.text)),
                        content: Text(
                          'VPN будет отключён и конфигурация удалена.',
                          style: TextStyle(color: mc.t2),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Отмена', style: TextStyle(color: mc.t2)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Сбросить', style: TextStyle(color: mc.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      try {
                        await ref.read(connectionNotifierProvider.notifier).abortConnection();
                      } catch (_) {}
                      try {
                        final repo = await ref.read(profileRepositoryProvider.future);
                        final either = await repo.watchAll().first;
                        final profiles = either.getOrElse((_) => const []);
                        for (final p in profiles) {
                          await repo.deleteById(p.id, p.active).run();
                        }
                      } catch (_) {}
                      await ref.read(Preferences.introCompleted.notifier).update(false);
                      if (context.mounted) context.go('/intro');
                    }
                  },
                ),
              ],
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.mc, required this.children});
  final MokyThemeData mc;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: mc.s1,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: mc.s2, indent: 16, endIndent: 0),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.mc,
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.showArrow = false,
    this.onTap,
    this.titleColor,
  });
  final MokyThemeData mc;
  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: trailing == null ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: mc.t2),
            const Gap(12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? mc.text,
                ),
              ),
            ),
            if (value != null)
              Text(value!, style: TextStyle(fontSize: 13, color: mc.t3)),
            if (trailing != null) trailing!,
            if (showArrow && trailing == null) ...[
              const Gap(4),
              Icon(Icons.chevron_right, size: 18, color: mc.t3),
            ],
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.mc, required this.onChanged});
  final bool value;
  final MokyThemeData mc;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: value ? mc.accent : mc.s3,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
