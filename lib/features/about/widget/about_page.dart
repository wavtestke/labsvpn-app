import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/model/constants.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);

    return Scaffold(
      backgroundColor: mc.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: mc.bg.withValues(alpha: 0.95),
                border: Border(bottom: BorderSide(color: mc.b1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: mc.s1,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: mc.b1),
                      ),
                      child: Icon(Icons.chevron_left, size: 18, color: mc.t2),
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'О приложении',
                    style: TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700, color: mc.text),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Logo hero
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [mc.accent, MokyColors.accentGradientEnd],
                              ),
                              border: Border.all(color: mc.accent.withValues(alpha: 0.3)),
                              boxShadow: [
                                BoxShadow(color: mc.accent.withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: const Icon(Icons.lock_outline, size: 44, color: Colors.white),
                          ),
                          const Gap(14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Labs',
                                style: TextStyle(fontFamily: 'Unbounded', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: mc.text),
                              ),
                              Text(
                                'VPN',
                                style: TextStyle(fontFamily: 'Unbounded', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: mc.accent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // About card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: mc.s1,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: mc.b1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'О НАС',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: mc.t3),
                                ),
                                const Gap(12),
                                Text(
                                  'LabsVpn — быстрый и надёжный VPN-сервис для защиты вашей конфиденциальности в интернете. Мы не храним логи и не передаём ваши данные третьим лицам.',
                                  style: TextStyle(fontSize: 13, color: mc.t2, height: 1.7),
                                ),
                              ],
                            ),
                          ),
                          const Gap(10),

                          // Links
                          Container(
                            decoration: BoxDecoration(
                              color: mc.s1,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: mc.b1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                _AboutLink(
                                  mc: mc,
                                  title: 'Политика конфиденциальности',
                                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.privacyPolicyUrl)),
                                ),
                                Divider(height: 1, color: mc.b1),
                                _AboutLink(
                                  mc: mc,
                                  title: 'Условия использования',
                                  onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.termsAndConditionsUrl)),
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),

                          Text(
                            '© 2026 LabsVpn. Все права защищены.',
                            style: TextStyle(fontSize: 11, color: mc.t3),
                          ),
                          const Gap(24),
                        ],
                      ),
                    ),
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

class _AboutLink extends StatelessWidget {
  const _AboutLink({required this.mc, required this.title, required this.onTap});
  final MokyThemeData mc;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: mc.text)),
            ),
            Icon(Icons.chevron_right, size: 14, color: mc.t3),
          ],
        ),
      ),
    );
  }
}
