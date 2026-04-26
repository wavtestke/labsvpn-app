import 'dart:async';
import 'package:flutter/material.dart';
import 'package:labsvpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:labsvpn/core/router/dialog/dialog_notifier.dart';
import 'package:labsvpn/core/theme/moky_colors.dart';
import 'package:labsvpn/features/connection/model/connection_status.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/connection/notifier/connection_start_time_notifier.dart';
import 'package:labsvpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:labsvpn/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mc = MokyThemeData.of(context);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

    final isConnected = connectionStatus.valueOrNull is Connected;
    final isConnecting = connectionStatus.valueOrNull is Connecting || connectionStatus.valueOrNull is Disconnecting;

    // Timer
    final connectionStartTime = ref.watch(connectionStartTimeProvider);
    final timerSeconds = useState(0);

    useEffect(() {
      Timer? timer;
      if (isConnected && connectionStartTime != null) {
        timerSeconds.value = DateTime.now().difference(connectionStartTime).inSeconds;
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          timerSeconds.value = DateTime.now().difference(connectionStartTime).inSeconds;
        });
      } else if (!isConnected) {
        timerSeconds.value = 0;
      }
      return () => timer?.cancel();
    }, [isConnected, connectionStartTime]);

    return GestureDetector(
      onTap: _buildOnTap(connectionStatus, requiresReconnect, ref),
      child: _PulsingButton(
        mc: mc,
        isConnected: isConnected,
        isConnecting: isConnecting,
        timerText: _formatTimer(timerSeconds.value),
      ),
    );
  }

  VoidCallback _buildOnTap(
    AsyncValue<ConnectionStatus> connectionStatus,
    bool? requiresReconnect,
    WidgetRef ref,
  ) {
    return switch (connectionStatus) {
      AsyncData(value: Connected()) when requiresReconnect == true => () async {
        final activeProfile = await ref.read(activeProfileProvider.future);
        await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
      },
      AsyncData(value: Disconnected()) || AsyncError() => () async {
        // No active profile — stay silent (no English "Choose a profile" dialog).
        // Profiles are added during intro flow and auto-activated.
        if (ref.read(activeProfileProvider).valueOrNull == null) return;
        await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      },
      AsyncData(value: Connected()) => () async {
        if (requiresReconnect == true &&
            await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
          await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
          return;
        }
        await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      },
      _ => () {},
    };
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    if (totalSeconds >= 3600) {
      final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '$m:$s';
  }
}

// ── Power button matching HTML reference 1-to-1 ──
// Light: .power-btn.off { bg:#fff; shadows: 8px #eaecf4 ring, 16px rgba(0,0,0,.04), drop }
// Dark:  .power-btn.off { bg:s1;   shadows: 8px s2 ring,      16px rgba(255,255,255,.03), drop }
// Both:  .power-btn.on  { radial-gradient(#3deb96 → #1db870), green glow shadows }
// Both:  .power-btn.connecting { base + accent spin-glow animation 1.2s }
class _PulsingButton extends StatefulWidget {
  const _PulsingButton({
    required this.mc,
    required this.isConnected,
    required this.isConnecting,
    required this.timerText,
  });
  final MokyThemeData mc;
  final bool isConnected;
  final bool isConnecting;
  final String timerText;

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _PulsingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnecting != oldWidget.isConnecting) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isConnecting) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild via ticker when actually pulsing; otherwise render static
    if (!widget.isConnecting) return _buildButton();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _buildButton(),
    );
  }

  Widget _buildButton() {
    final mc = widget.mc;
    final isConnected = widget.isConnected;
    final isConnecting = widget.isConnecting;
    final isDark = mc.isDark;

    // Triangle pulse 0→1→0 for connecting "spin-glow" keyframes
    final t = _controller.value;
    final pulse = isConnecting ? (t <= 0.5 ? t * 2 : (1 - t) * 2) : 0.0;

    // Concentric ring colors (outer → inner)
    // 16px outer ring (faint tint between 8 and 16 px from button edge)
    final Color ring16Color = isConnected
        ? const Color(0xFF2DE08A).withValues(alpha: 0.04)
        : isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.04);

    // 8px inner ring (brighter base — s2 in dark, #eaecf4 in light)
    Color ring8Color = isConnected
        ? const Color(0xFF2DE08A).withValues(alpha: 0.08)
        : isDark
            ? mc.s2 // 0xFF222328
            : const Color(0xFFEAECF4);

    // During connecting state, inner ring pulses toward accent tint
    if (isConnecting) {
      final accentTint = mc.accent.withValues(alpha: isDark ? 0.1 : 0.15);
      ring8Color = Color.lerp(ring8Color, accentTint, pulse) ?? ring8Color;
    }

    // Shadows for the 160px button itself
    final List<BoxShadow> shadows = [];
    if (isConnected) {
      // Green glow
      shadows.add(BoxShadow(
        color: const Color(0xFF2DE08A).withValues(alpha: 0.3),
        blurRadius: 60,
      ));
      shadows.add(BoxShadow(
        color: const Color(0xFF2DE08A).withValues(alpha: 0.25),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ));
    } else if (isConnecting) {
      // Accent spin-glow (pulsing)
      // HTML: 0 0 30px rgba(accent,.2) → 0 0 40px rgba(accent,.35) at 50%
      shadows.add(BoxShadow(
        color: mc.accent.withValues(alpha: 0.2 + pulse * 0.15),
        blurRadius: 30 + pulse * 10,
      ));
      // HTML: 0 0 60px rgba(accent,.05) → 0 0 80px rgba(accent,.1) at 50%
      shadows.add(BoxShadow(
        color: mc.accent.withValues(alpha: 0.05 + pulse * 0.05),
        blurRadius: 60 + pulse * 20,
      ));
      // Base drop
      shadows.add(BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ));
    } else {
      // Off state — drop shadow
      shadows.add(BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ));
    }

    // The actual 160px button with gradient/color and shadows
    final Widget button = Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? null : (isDark ? mc.s1 : Colors.white),
        gradient: isConnected
            ? const RadialGradient(
                // HTML: radial-gradient(circle at 40% 35%, #3deb96, #1db870)
                // Flutter Alignment: 40% = -0.2, 35% = -0.3
                center: Alignment(-0.2, -0.3),
                radius: 0.85,
                colors: [Color(0xFF3DEB96), Color(0xFF1DB870)],
              )
            : null,
        boxShadow: shadows,
      ),
      child: Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(
            painter: _PowerIconPainter(
              color: isConnected
                  // Matches CSS: light→rgba(255,255,255,.7), dark→rgba(0,0,0,.5)
                  ? (isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.7))
                  : mc.t2,
            ),
          ),
        ),
      ),
    );

    // Nest in two ring circles (8px + 16px expansion) to emulate CSS multi-ring shadows
    return SizedBox(
      width: 192,
      height: 192,
      child: Center(
        child: Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring16Color,
          ),
          child: Center(
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ring8Color,
              ),
              child: Center(child: button),
            ),
          ),
        ),
      ),
    );
  }
}

// Matches SVG from hitvpn.html:
// <path d="M22 14.5 C17.5 17.5 14 22.5 14 28.5 C14 38.7 22.3 47 32.5 47
//          C42.7 47 51 38.7 51 28.5 C51 22.5 47.5 17.5 43 14.5"/>
// <line x1="32.5" y1="10" x2="32.5" y2="30"/>
// viewBox 0 0 64 64
class _PowerIconPainter extends CustomPainter {
  final Color color;
  _PowerIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Scale SVG coordinates (0..64) to canvas size
    final sx = size.width / 64;
    final sy = size.height / 64;
    double x(double v) => v * sx;
    double y(double v) => v * sy;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arc path — open at top, matches SVG cubic curves exactly
    final path = Path()
      ..moveTo(x(22), y(14.5))
      ..cubicTo(x(17.5), y(17.5), x(14), y(22.5), x(14), y(28.5))
      ..cubicTo(x(14), y(38.7), x(22.3), y(47), x(32.5), y(47))
      ..cubicTo(x(42.7), y(47), x(51), y(38.7), x(51), y(28.5))
      ..cubicTo(x(51), y(22.5), x(47.5), y(17.5), x(43), y(14.5));
    canvas.drawPath(path, paint);

    // Vertical power line: x=32.5, y=10 → y=30
    canvas.drawLine(Offset(x(32.5), y(10)), Offset(x(32.5), y(30)), paint);
  }

  @override
  bool shouldRepaint(covariant _PowerIconPainter oldDelegate) => oldDelegate.color != color;
}
