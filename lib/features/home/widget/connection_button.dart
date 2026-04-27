import 'dart:async';
import 'package:flutter/material.dart';
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
    final isConnecting = connectionStatus.valueOrNull is Connecting ||
        connectionStatus.valueOrNull is Disconnecting;

    final connectionStartTime = ref.watch(connectionStartTimeProvider);
    final timerSeconds = useState(0);

    useEffect(() {
      Timer? timer;
      if (isConnected && connectionStartTime != null) {
        timerSeconds.value =
            DateTime.now().difference(connectionStartTime).inSeconds;
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          timerSeconds.value =
              DateTime.now().difference(connectionStartTime).inSeconds;
        });
      } else if (!isConnected) {
        timerSeconds.value = 0;
      }
      return () => timer?.cancel();
    }, [isConnected, connectionStartTime]);

    return GestureDetector(
      onTap: _buildOnTap(connectionStatus, requiresReconnect, ref),
      child: _PowerButton(
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
        await ref
            .read(connectionNotifierProvider.notifier)
            .reconnect(activeProfile);
      },
      AsyncData(value: Disconnected()) || AsyncError() => () async {
        if (ref.read(activeProfileProvider).valueOrNull == null) return;
        await ref
            .read(connectionNotifierProvider.notifier)
            .toggleConnection();
      },
      AsyncData(value: Connected()) => () async {
        if (requiresReconnect == true &&
            await ref
                .read(dialogNotifierProvider.notifier)
                .showExperimentalFeatureNotice()) {
          await ref.read(connectionNotifierProvider.notifier).reconnect(
              await ref.read(activeProfileProvider.future));
          return;
        }
        await ref
            .read(connectionNotifierProvider.notifier)
            .toggleConnection();
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

class _PowerButton extends StatefulWidget {
  const _PowerButton({
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
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant _PowerButton old) {
    super.didUpdateWidget(old);
    if (widget.isConnecting != old.isConnecting ||
        widget.isConnected != old.isConnected) _sync();
  }

  void _sync() {
    if (widget.isConnecting) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnecting) {
      return AnimatedBuilder(
          animation: _controller, builder: (_, __) => _build());
    }
    return _build();
  }

  Widget _build() {
    final mc = widget.mc;
    final isOn = widget.isConnected;
    final isConnecting = widget.isConnecting;

    // pulse 0→1→0
    final t = _controller.value;
    final pulse = isConnecting ? (t <= 0.5 ? t * 2 : (1 - t) * 2) : 0.0;

    final Color ringColor = isOn
        ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
        : isConnecting
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1 + pulse * 0.15)
            : Colors.transparent;

    final List<BoxShadow> shadows = isOn
        ? [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
              blurRadius: 40,
            ),
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              blurRadius: 80,
            ),
          ]
        : isConnecting
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50)
                      .withValues(alpha: 0.1 + pulse * 0.15),
                  blurRadius: 40,
                ),
              ]
            : [];

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          if (isOn || isConnecting)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringColor,
              ),
            ),
          // Button
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? const Color(0xFF4CAF50) : mc.s2,
              border: Border.all(
                color: isOn
                    ? const Color(0xFF4CAF50)
                    : mc.s3,
                width: 3,
              ),
              boxShadow: shadows,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.power_settings_new,
                  size: 52,
                  color: isOn ? Colors.white : mc.t3,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.timerText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isOn
                        ? Colors.white.withValues(alpha: 0.9)
                        : mc.t3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
