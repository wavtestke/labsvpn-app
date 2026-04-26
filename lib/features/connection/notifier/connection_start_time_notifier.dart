import 'package:labsvpn/features/connection/model/connection_status.dart';
import 'package:labsvpn/features/connection/notifier/connection_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_start_time_notifier.g.dart';

/// Stores the DateTime when VPN connected. Survives widget rebuilds / app minimize.
/// Returns null when disconnected.
@Riverpod(keepAlive: true)
class ConnectionStartTime extends _$ConnectionStartTime {
  @override
  DateTime? build() {
    ref.listen(connectionNotifierProvider, (previous, next) {
      final wasConnected = previous?.valueOrNull is Connected;
      final isConnected = next.valueOrNull is Connected;

      if (!wasConnected && isConnected) {
        // Just connected — save timestamp
        state = DateTime.now();
      } else if (wasConnected && !isConnected) {
        // Disconnected — clear timestamp
        state = null;
      }
    });
    return null;
  }
}
