import 'package:flutter/material.dart';
import 'package:labsvpn/core/localization/translations.dart';
import 'package:labsvpn/core/notification/in_app_notification_controller.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/features/connection/model/connection_status.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:labsvpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:labsvpn/features/settings/data/battery_optimization_repository.dart';
import 'package:labsvpn/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:labsvpn/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionWrapper extends StatefulHookConsumerWidget {
  const ConnectionWrapper(this.child, {super.key});

  final Widget child;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends ConsumerState<ConnectionWrapper> with AppLogger {
  @override
  Widget build(BuildContext context) {
    ref.listen(connectionNotifierProvider, (previous, next) {
      // #6 — notify on unexpected VPN disconnect
      final wasConnected = previous?.valueOrNull is Connected;
      final isDisconnected = next.valueOrNull is Disconnected;
      final startedByUser = ref.read(Preferences.startedByUser);

      if (wasConnected && isDisconnected && startedByUser) {
        // startedByUser is still true → user didn't tap disconnect → unexpected drop
        ref.read(inAppNotificationControllerProvider).showErrorToast(
          'VPN отключился. Нажмите кнопку для переподключения.',
        );
      }
    });

    ref.listen(configOptionNotifierProvider, (previous, next) async {
      if (next case AsyncData(value: true)) {
        final t = ref.read(translationsProvider).requireValue;
        ref.read(inAppNotificationControllerProvider).showInfoToast(t.connection.reconnectMsg);
        await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
      }
    });

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // #5 — request battery optimization exemption once, 3s after launch
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final repo = BatteryOptimizationRepositoryImpl();
      final isIgnoring = await repo.isIgnoringBatteryOptimizations();
      if (!mounted) return;
      if (isIgnoring == false) {
        await repo.requestIgnoreBatteryOptimizations();
      }
    });
  }
}
