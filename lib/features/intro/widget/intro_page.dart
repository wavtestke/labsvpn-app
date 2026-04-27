import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:labsvpn/core/analytics/analytics_controller.dart';
import 'package:labsvpn/core/localization/locale_preferences.dart';
import 'package:labsvpn/core/localization/translations.dart';
import 'package:labsvpn/core/model/region.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/profile/notifier/profile_notifier.dart';
import 'package:labsvpn/features/settings/data/config_option_repository.dart';
import 'package:labsvpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IntroPage extends HookConsumerWidget with PresLogger {
  const IntroPage({super.key});

  static bool locationInfoLoaded = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final isStarting = useState(false);
    final linkController = useTextEditingController();
    final linkError = useState<String?>(null);

    if (!locationInfoLoaded) {
      autoSelectRegion(ref);
      locationInfoLoaded = true;
    }

    // Auto-paste subscription URL from clipboard on first open
    useEffect(() {
      () async {
        try {
          final clip = await Clipboard.getData(Clipboard.kTextPlain);
          final text = clip?.text?.trim() ?? '';
          if (text.isEmpty || linkController.text.isNotEmpty) return;
          final isSubUrl = RegExp(
            r'^https?://[\w.\-]+/sub/[\w\-_=]+$',
            caseSensitive: false,
          ).hasMatch(text);
          final isVless = text.startsWith('vless://') || text.startsWith('vmess://') ||
              text.startsWith('trojan://') || text.startsWith('ss://') || text.startsWith('hy2://');
          if (isSubUrl || isVless) {
            linkController.text = text;
          }
        } catch (_) {}
      }();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: mc.bg,
      body: Stack(
        children: [
          // ── Background: Hexagon grid + gradient + glow ──
          Positioned.fill(
            child: CustomPaint(
              painter: _HexagonGridPainter(mc.accent),
            ),
          ),
          // Gradient overlay to fade hex
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    mc.bg.withValues(alpha: 0.0),
                    mc.bg.withValues(alpha: 0.3),
                    mc.bg,
                  ],
                  stops: const [0.0, 0.45, 0.75],
                ),
              ),
            ),
          ),
          // Glow blob
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mc.accent.withValues(alpha: mc.isDark ? 0.12 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // Logo row (fixed at top)
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                  child: Row(
                    children: [
                      Text(
                        'labs',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mc.text,
                        ),
                      ),
                      Text(
                        'vpn',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: mc.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shield hero (fixed size, not Expanded)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: _ShieldHero(mc: mc),
                          ),
                        ),

                        // Bottom content
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1.2,
                              color: mc.text,
                            ),
                            children: [
                              const TextSpan(text: 'Добро\nпожаловать\nв '),
                              TextSpan(
                                text: 'LabsVpn',
                                style: TextStyle(color: mc.accent),
                              ),
                            ],
                          ),
                        ),
                        const Gap(14),
                        Text(
                          'Вставьте ссылку конфигурации из личного кабинета LabsVpn и нажмите «Настроить»',
                          style: TextStyle(
                            fontSize: 14,
                            color: mc.t2,
                            height: 1.65,
                          ),
                        ),
                        const Gap(14),
                        // Config URL input
                        TextField(
                          controller: linkController,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: mc.text,
                          ),
                          decoration: InputDecoration(
                            hintText: 'https://labsvpn.app/config/...',
                            hintStyle: TextStyle(color: mc.t3, fontFamily: 'monospace', fontSize: 13),
                            errorText: linkError.value,
                            filled: true,
                            fillColor: mc.isDark ? mc.s2 : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: mc.b1, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: mc.b1, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: mc.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const Gap(14),
                        // НАСТРОИТЬ button
                        SizedBox(
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
                                BoxShadow(
                                  color: mc.accent.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isStarting.value
                                    ? null
                                    : () async {
                                        final link = linkController.text.trim();
                                        if (link.isEmpty) {
                                          linkError.value = 'Вставьте ссылку конфигурации';
                                          return;
                                        }
                                        // Validate: must be a URL (http/https/vless/vmess/trojan/ss/ssr/hiddify/clash/sing-box)
                                        // or a valid base64 subscription
                                        final isUrl = RegExp(
                                          r'^(https?|vless|vmess|trojan|ss|ssr|hiddify|clash|clashmeta|sing-box)://',
                                          caseSensitive: false,
                                        ).hasMatch(link);
                                        final isBase64 = RegExp(r'^[A-Za-z0-9+/=\n\r]{20,}$').hasMatch(link);
                                        if (!isUrl && !isBase64) {
                                          linkError.value = 'Введите корректную ссылку конфигурации';
                                          return;
                                        }
                                        linkError.value = null;
                                        isStarting.value = true;

                                        try {
                                          await ref.read(addProfileNotifierProvider.notifier).addClipboard(link);
                                        } catch (e) {
                                          linkError.value = 'Неверная ссылка';
                                          isStarting.value = false;
                                          return;
                                        }

                                        try {
                                          await ref.read(analyticsControllerProvider.notifier).disableAnalytics();
                                        } catch (_) {}

                                        await ref.read(Preferences.introCompleted.notifier).update(true);
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 17),
                                  child: Center(
                                    child: isStarting.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          )
                                        : const Text(
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
                        const Gap(40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> autoSelectRegion(WidgetRef ref) async {
    try {
      final countryCode = RegionDetector.detect();
      final regionLocale = _getRegionLocale(countryCode);
      await ref.read(ConfigOptions.region.notifier).update(regionLocale.region);
      await ref.read(ConfigOptions.directDnsAddress.notifier).reset();
      await ref.read(localePreferencesProvider.notifier).changeLocale(regionLocale.locale);
    } catch (_) {}
  }

  RegionLocale _getRegionLocale(String country) {
    switch (country.toUpperCase()) {
      case "IR": return RegionLocale(Region.ir, AppLocale.fa);
      case "CN": return RegionLocale(Region.cn, AppLocale.zhCn);
      case "RU": return RegionLocale(Region.ru, AppLocale.ru);
      case "AF": return RegionLocale(Region.af, AppLocale.fa);
      case "BR": return RegionLocale(Region.br, AppLocale.ptBr);
      case "TR": return RegionLocale(Region.tr, AppLocale.tr);
      default: return RegionLocale(Region.other, AppLocale.en);
    }
  }
}

class RegionLocale {
  final Region region;
  final AppLocale locale;
  RegionLocale(this.region, this.locale);
}

class RegionDetector {
  static String detect() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inMinutes;
    if (offset == 210 || offset == 270) return 'IR';
    final tz = now.timeZoneName.toLowerCase();
    if (tz.contains('moscow') || tz == 'msk') return 'RU';
    if (tz.contains('china') || tz.contains('beijing')) return 'CN';
    if (tz.contains('turkey') || tz.contains('istanbul')) return 'TR';
    if (tz == 'brt' || tz.contains('brazil')) return 'BR';
    return 'US';
  }
}

// ── Shield Hero with glow animation ──
class _ShieldHero extends StatefulWidget {
  const _ShieldHero({required this.mc});
  final MokyThemeData mc;

  @override
  State<_ShieldHero> createState() => _ShieldHeroState();
}

class _ShieldHeroState extends State<_ShieldHero> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowScale = 1.0 + _controller.value * 0.1;
        final glowOpacity = 0.6 + _controller.value * 0.4;
        return SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Transform.scale(
                scale: glowScale,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.mc.accent.withValues(alpha: 0.15 * glowOpacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Shield
              CustomPaint(
                size: const Size(160, 180),
                painter: _ShieldPainter(widget.mc.accent),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shield painter matching HTML SVG ──
class _ShieldPainter extends CustomPainter {
  final Color accent;
  _ShieldPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer shield
    final outerPath = Path()
      ..moveTo(w * 0.5, h * 0.044)
      ..lineTo(w * 0.1, h * 0.2)
      ..lineTo(w * 0.1, h * 0.489)
      ..quadraticBezierTo(w * 0.1, h * 0.72, w * 0.5, h * 0.956)
      ..quadraticBezierTo(w * 0.9, h * 0.72, w * 0.9, h * 0.489)
      ..lineTo(w * 0.9, h * 0.2)
      ..close();

    canvas.drawPath(outerPath, Paint()..color = accent.withValues(alpha: 0.08)..style = PaintingStyle.fill);
    canvas.drawPath(outerPath, Paint()..color = accent.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Inner shield
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.133)
      ..lineTo(w * 0.2, h * 0.256)
      ..lineTo(w * 0.2, h * 0.489)
      ..quadraticBezierTo(w * 0.2, h * 0.667, w * 0.5, h * 0.867)
      ..quadraticBezierTo(w * 0.8, h * 0.667, w * 0.8, h * 0.489)
      ..lineTo(w * 0.8, h * 0.256)
      ..close();

    canvas.drawPath(innerPath, Paint()..color = accent.withValues(alpha: 0.05)..style = PaintingStyle.fill);
    canvas.drawPath(innerPath, Paint()..color = accent.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    // Lock body
    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.594), width: w * 0.275, height: h * 0.189),
      const Radius.circular(6),
    );
    canvas.drawRRect(lockRect, Paint()..color = accent.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawRRect(lockRect, Paint()..color = accent.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.8);

    // Lock shackle
    final shacklePath = Path()
      ..moveTo(w * 0.4125, h * 0.5)
      ..lineTo(w * 0.4125, h * 0.433)
      ..quadraticBezierTo(w * 0.4125, h * 0.378, w * 0.5, h * 0.378)
      ..quadraticBezierTo(w * 0.5875, h * 0.378, w * 0.5875, h * 0.433)
      ..lineTo(w * 0.5875, h * 0.5);
    canvas.drawPath(shacklePath, Paint()..color = accent.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round);

    // Keyhole
    canvas.drawCircle(Offset(w * 0.5, h * 0.578), w * 0.031, Paint()..color = accent.withValues(alpha: 0.8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.6), width: w * 0.031, height: h * 0.044),
        const Radius.circular(2),
      ),
      Paint()..color = accent.withValues(alpha: 0.8),
    );

    // Decorative dots
    canvas.drawCircle(Offset(w * 0.1875, h * 0.333), 2.5, Paint()..color = accent.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(w * 0.8125, h * 0.4), 2, Paint()..color = const Color(0xFF2DE08A).withValues(alpha: 0.4));
    canvas.drawCircle(Offset(w * 0.15, h * 0.556), 1.5, Paint()..color = accent.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(w * 0.85, h * 0.611), 2, Paint()..color = accent.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) => oldDelegate.accent != accent;
}

// ── Hexagon grid background ──
class _HexagonGridPainter extends CustomPainter {
  final Color accent;
  _HexagonGridPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double hexW = 50;
    const double hexH = 58;

    for (double y = 0; y < size.height * 0.6; y += hexH) {
      for (double x = 0; x < size.width; x += hexW) {
        _drawHexagon(canvas, x + hexW / 2, y + hexH / 2, hexW / 2, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * pi / 180;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonGridPainter oldDelegate) => oldDelegate.accent != accent;
}
