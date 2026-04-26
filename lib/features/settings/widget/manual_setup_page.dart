import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ManualSetupPage extends HookConsumerWidget {
  const ManualSetupPage({super.key});

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
                  _BackButton(mc: mc, onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  Text(
                    'Ручная настройка',
                    style: TextStyle(fontFamily: 'Unbounded', fontSize: 16, fontWeight: FontWeight.w700, color: mc.text),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: mc.accentDim,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: mc.accentMid),
                              boxShadow: [BoxShadow(color: mc.accent.withValues(alpha: 0.15), blurRadius: 40)],
                            ),
                            child: Icon(Icons.settings, size: 36, color: mc.accent),
                          ),
                          const Gap(14),
                          Text(
                            'Ручная настройка',
                            style: TextStyle(fontFamily: 'Unbounded', fontSize: 20, fontWeight: FontWeight.w700, color: mc.text, letterSpacing: -0.3),
                          ),
                          const Gap(8),
                          Text(
                            'Настройте VPN вручную через конфигурацию из личного кабинета LabsVpn',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: mc.t2, height: 1.65),
                          ),
                        ],
                      ),
                    ),

                    // Steps
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'КАК НАСТРОИТЬ',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: mc.t3),
                          ),
                          const Gap(10),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: mc.s1,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: mc.b1),
                            ),
                            child: Column(
                              children: [
                                _StepItem(
                                  mc: mc,
                                  number: '1',
                                  title: 'Скопируйте ссылку',
                                  description: 'Скопируйте ссылку конфигурации из личного кабинета LabsVpn',
                                ),
                                Divider(height: 28, color: mc.b1),
                                _StepItem(
                                  mc: mc,
                                  number: '2',
                                  title: 'Нажмите «Настроить»',
                                  description: 'Нажмите кнопку ниже — приложение автоматически применит конфигурацию из буфера обмена',
                                ),
                                Divider(height: 28, color: mc.b1),
                                _StepItem(
                                  mc: mc,
                                  number: '✓',
                                  title: 'Готово',
                                  description: 'VPN настроен и готов к подключению',
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // CTA button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [mc.accent, MokyColors.accentGradientEnd],
                            ),
                            boxShadow: [
                              BoxShadow(color: mc.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                final clipboardText = data?.text;
                                if (clipboardText != null && clipboardText.isNotEmpty) {
                                  try {
                                    await ref.read(addProfileNotifierProvider.notifier).addClipboard(clipboardText);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Настройка применена!'),
                                          backgroundColor: mc.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Неверная ссылка в буфере обмена'),
                                          backgroundColor: mc.red,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Буфер обмена пуст'),
                                        backgroundColor: mc.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 17),
                                child: Center(
                                  child: Text(
                                    'НАСТРОИТЬ',
                                    style: TextStyle(
                                      fontFamily: 'Unbounded',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(32),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.mc, required this.onTap});
  final MokyThemeData mc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.mc,
    required this.number,
    required this.title,
    required this.description,
    this.isLast = false,
  });
  final MokyThemeData mc;
  final String number;
  final String title;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isCheck = number == '✓';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCheck ? mc.greenDim : mc.accentDim,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: isCheck ? mc.greenMid : mc.accentMid),
          ),
          child: Center(
            child: isCheck
                ? Icon(Icons.check, size: 14, color: mc.green)
                : Text(
                    number,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: mc.accent,
                    ),
                  ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mc.text)),
                const Gap(3),
                Text(description, style: TextStyle(fontSize: 12, color: mc.t3, height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
