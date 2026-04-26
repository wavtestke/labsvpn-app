import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:labsvpn/core/model/constants.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/profile/data/profile_data_providers.dart';
import 'package:labsvpn/features/settings/widget/manual_setup_page.dart';
import 'package:labsvpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends HookConsumerWidget {
  SettingsPage({super.key, String? section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final autoConnect = useState(false);
    final showACInfo = useState(false);

    useEffect(() {
      SharedPreferences.getInstance().then((prefs) {
        autoConnect.value = prefs.getBool('auto_connect') ?? false;
      });
      return null;
    }, []);

    return Scaffold(
      backgroundColor: mc.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: mc.bg.withValues(alpha: 0.94),
                border: Border(bottom: BorderSide(color: mc.b1)),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: mc.s1,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: mc.b1),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: mc.t2),
                    ),
                  ),
                  Text(
                    'moky',
                    style: TextStyle(fontFamily: 'Unbounded', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: mc.text),
                  ),
                  Text(
                    'vpn',
                    style: TextStyle(fontFamily: 'Unbounded', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: mc.accent),
                  ),
                  const Spacer(),
                  Text('Настройки', style: TextStyle(fontSize: 12, color: mc.t3, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Text(
                      'Настройки',
                      style: TextStyle(fontFamily: 'Unbounded', fontSize: 22, fontWeight: FontWeight.w700, color: mc.text),
                    ),
                  ),

                  // ── CONNECTION section ──
                  _SectionLabel('ПОДКЛЮЧЕНИЕ', mc),
                  _SettingsGroup(
                    mc: mc,
                    children: [
                      _SettingsRow(
                        mc: mc,
                        icon: Icons.edit_outlined,
                        title: 'Ручная настройка',
                        showArrow: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ManualSetupPage()),
                          );
                        },
                      ),
                      _SettingsRow(
                        mc: mc,
                        icon: Icons.flash_on_outlined,
                        title: 'Автоподключение',
                        trailing: _MokyToggle(
                          value: autoConnect.value,
                          mc: mc,
                          onChanged: (val) async {
                            autoConnect.value = val;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('auto_connect', val);
                          },
                        ),
                        infoButton: true,
                        onInfoTap: () => showACInfo.value = !showACInfo.value,
                      ),
                      // Auto-connect info card
                      if (showACInfo.value)
                        _AutoConnectInfoCard(mc: mc),
                    ],
                  ),

                  // ── OTHER section ──
                  _SectionLabel('ПРОЧЕЕ', mc),
                  _SettingsGroup(
                    mc: mc,
                    children: [
                      _SettingsRow(
                        mc: mc,
                        icon: Icons.delete_outline,
                        title: 'Сбросить конфигурацию',
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Сбросить конфигурацию?'),
                              content: const Text('VPN будет отключён и конфигурация удалена. Вам нужно будет ввести ссылку заново.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Сбросить', style: TextStyle(color: mc.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            // 1. Disconnect VPN if active
                            try {
                              await ref.read(connectionNotifierProvider.notifier).abortConnection();
                            } catch (_) {}
                            // 2. Delete all profiles from DB
                            try {
                              final repo = await ref.read(profileRepositoryProvider.future);
                              final either = await repo.watchAll().first;
                              final profiles = either.getOrElse((_) => const []);
                              for (final p in profiles) {
                                await repo.deleteById(p.id, p.active).run();
                              }
                            } catch (_) {}
                            // 3. Reset intro flag → router will redirect to /intro
                            await ref.read(Preferences.introCompleted.notifier).update(false);
                            if (context.mounted) context.go('/intro');
                          }
                        },
                      ),
                      _SettingsRow(
                        mc: mc,
                        icon: Icons.email_outlined,
                        title: 'Написать в поддержку',
                        onTap: () => UriUtils.tryLaunch(Uri.parse(Constants.supportUrl)),
                      ),
                      _SettingsRow(
                        mc: mc,
                        icon: Icons.info_outline,
                        title: 'О приложении',
                        showArrow: true,
                        onTap: () => context.goNamed('about'),
                      ),
                    ],
                  ),

                  // ── Banner ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _UseMokyBanner(mc: mc),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.mc);
  final String text;
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.3, color: mc.t3),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: mc.s1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: mc.b1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1 && children[i] is _SettingsRow)
                Divider(height: 1, indent: 0, color: mc.b1),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.mc,
    required this.icon,
    required this.title,
    this.showArrow = false,
    this.onTap,
    this.trailing,
    this.infoButton = false,
    this.onInfoTap,
  });
  final MokyThemeData mc;
  final IconData icon;
  final String title;
  final bool showArrow;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool infoButton;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: trailing != null ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: mc.s2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: mc.t2),
            ),
            const Gap(12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: mc.text)),
                  ),
                  if (infoButton) ...[
                    const Gap(6),
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mc.s3,
                          border: Border.all(color: mc.b2),
                        ),
                        child: Icon(Icons.info_outline, size: 9, color: mc.t3),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow)
              Icon(Icons.chevron_right, size: 14, color: mc.t3),
          ],
        ),
      ),
    );
  }
}

class _MokyToggle extends StatelessWidget {
  const _MokyToggle({required this.value, required this.mc, required this.onChanged});
  final bool value;
  final MokyThemeData mc;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: value ? mc.accent : mc.b2,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoConnectInfoCard extends StatelessWidget {
  const _AutoConnectInfoCard({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: mc.b1)),
        color: mc.accent.withValues(alpha: 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: mc.accentDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: mc.accentMid),
            ),
            child: Icon(Icons.info_outline, size: 15, color: mc.accent),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Что это такое?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: mc.text),
                ),
                const Gap(5),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: mc.t2, height: 1.65),
                    children: [
                      const TextSpan(text: 'VPN будет '),
                      TextSpan(
                        text: 'включаться автоматически',
                        style: TextStyle(color: mc.text, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' каждый раз при запуске приложения. Не нужно нажимать кнопку вручную.'),
                    ],
                  ),
                ),
                const Gap(10),
                _InfoBullet(color: mc.green, text: 'Защита включается сама — вы всегда под VPN', mc: mc),
                const Gap(6),
                _InfoBullet(color: const Color(0xFFFFB347), text: 'Может немного увеличить расход батареи', mc: mc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.color, required this.text, required this.mc});
  final Color color;
  final String text;
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const Gap(8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: mc.t2)),
        ),
      ],
    );
  }
}

// ── "Use only LabsVpn" banner (matches HTML SVG illustration) ──
class _UseMokyBanner extends StatelessWidget {
  const _UseMokyBanner({required this.mc});
  final MokyThemeData mc;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: mc.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [mc.s2, const Color(0xFF1A1E2E)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8EDF8), Color(0xFFDDE4F5)],
              ),
        border: Border.all(color: mc.isDark ? mc.b1 : const Color(0xFFC8D0E8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: 160,
        child: CustomPaint(
          painter: _BannerPainter(mc: mc),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// CustomPainter replicating the HTML SVG banner illustration
class _BannerPainter extends CustomPainter {
  final MokyThemeData mc;
  _BannerPainter({required this.mc});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final accent = mc.accent;
    final green = mc.green;

    // ── Background grid ──
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = 0; x <= w; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // ── Glow: accent (right side) ──
    final glowRect = Rect.fromCenter(
      center: Offset(w * 0.75, h * 0.5),
      width: w * 0.6,
      height: h * 0.8,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(glowRect),
    );

    // ── Glow: green (left-bottom) ──
    final glowRect2 = Rect.fromCenter(
      center: Offset(w * 0.2, h * 0.6),
      width: w * 0.5,
      height: h * 0.6,
    );
    canvas.drawOval(
      glowRect2,
      Paint()
        ..shader = RadialGradient(
          colors: [green.withValues(alpha: 0.08), Colors.transparent],
        ).createShader(glowRect2),
    );

    // ── Shield (right side, matching HTML position) ──
    final sx = w * 0.75; // shield center x
    final sy = h * 0.42; // shield center y
    final shieldPath = Path()
      ..moveTo(sx, sy - 41)
      ..lineTo(sx - 30, sy - 27)
      ..lineTo(sx - 30, sy - 1)
      ..quadraticBezierTo(sx - 30, sy + 19, sx, sy + 41)
      ..quadraticBezierTo(sx + 30, sy + 19, sx + 30, sy - 1)
      ..lineTo(sx + 30, sy - 27)
      ..close();
    canvas.drawPath(shieldPath, Paint()..color = accent.withValues(alpha: 0.12));
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Checkmark inside shield ──
    final checkPath = Path()
      ..moveTo(sx - 13, sy)
      ..lineTo(sx - 5, sy + 8)
      ..lineTo(sx + 13, sy - 10);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Orbiting dots ──
    canvas.drawCircle(Offset(sx, sy - 41), 3, Paint()..color = accent.withValues(alpha: 0.6));
    canvas.drawCircle(Offset(sx + 30, sy - 1), 2, Paint()..color = green.withValues(alpha: 0.5));
    canvas.drawCircle(Offset(sx - 30, sy + 16), 2.5, Paint()..color = accent.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(sx - 12, sy + 39), 2, Paint()..color = green.withValues(alpha: 0.4));

    // ── Connection lines (dashed-like with short segments) ──
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    _drawDashedLine(canvas, Offset(sx - 30, sy - 14), Offset(sx - 75, sy - 14), linePaint);
    _drawDashedLine(canvas, Offset(sx - 30, sy + 6), Offset(sx - 70, sy + 21), linePaint..color = accent.withValues(alpha: 0.15));
    _drawDashedLine(canvas, Offset(sx + 30, sy - 14), Offset(sx + 60, sy - 29), linePaint..color = accent.withValues(alpha: 0.15));

    // ── Small node circles at line endpoints ──
    _drawNode(canvas, Offset(sx - 75, sy - 14), 5, accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.4));
    _drawNode(canvas, Offset(sx - 70, sy + 21), 4, green.withValues(alpha: 0.3), green.withValues(alpha: 0.4));
    _drawNode(canvas, Offset(sx + 60, sy - 29), 4, accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.35));

    // ── Lock icon (bottom right) ──
    final lx = w * 0.88;
    final ly = h * 0.75;
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(lx, ly + 5), width: 22, height: 18),
      const Radius.circular(3),
    );
    canvas.drawRRect(lockBody, Paint()..color = accent.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    final shacklePath = Path()
      ..moveTo(lx - 7, ly - 4)
      ..lineTo(lx - 7, ly - 9)
      ..quadraticBezierTo(lx - 7, ly - 15, lx, ly - 15)
      ..quadraticBezierTo(lx + 7, ly - 15, lx + 7, ly - 9)
      ..lineTo(lx + 7, ly - 4);
    canvas.drawPath(shacklePath, Paint()..color = accent.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawCircle(Offset(lx, ly + 5), 2.5, Paint()..color = accent.withValues(alpha: 0.35));

    // ── Text ──
    _drawText(canvas, 'Используй только', Offset(24, h * 0.3),
        'Unbounded', 18, FontWeight.w700, mc.isDark ? mc.text : const Color(0xFF1A2240));
    _drawText(canvas, 'LabsVpn', Offset(24, h * 0.3 + 24),
        'Unbounded', 18, FontWeight.w700, accent.withValues(alpha: 0.9));
    _drawText(canvas, 'Не переключай через системные', Offset(24, h * 0.3 + 54),
        'Onest', 12, FontWeight.w400, (mc.isDark ? mc.t2 : Colors.black).withValues(alpha: 0.45));
    _drawText(canvas, 'настройки — это нарушит работу', Offset(24, h * 0.3 + 72),
        'Onest', 12, FontWeight.w400, (mc.isDark ? mc.t2 : Colors.black).withValues(alpha: 0.45));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (dx * dx + dy * dy);
    if (dist == 0) return;
    final len = dist > 0 ? (dx * dx + dy * dy) : 1.0;
    final totalLen = len > 0 ? (dx.abs() + dy.abs()) : 1.0; // approximate
    final ux = dx / totalLen;
    final uy = dy / totalLen;
    double d = 0;
    while (d < totalLen) {
      final segEnd = (d + dashLen).clamp(0, totalLen);
      canvas.drawLine(
        Offset(start.dx + ux * d, start.dy + uy * d),
        Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
        paint,
      );
      d += dashLen + gapLen;
    }
  }

  void _drawNode(Canvas canvas, Offset center, double r, Color strokeColor, Color fillColor) {
    canvas.drawCircle(center, r, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawCircle(center, r * 0.4, Paint()..color = fillColor);
  }

  void _drawText(Canvas canvas, String text, Offset offset, String fontFamily, double fontSize, FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: fontFamily, fontSize: fontSize, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BannerPainter oldDelegate) => oldDelegate.mc != mc;
}
