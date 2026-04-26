import 'package:flutter/foundation.dart';
import 'package:labsvpn/core/app_info/app_info_provider.dart';
import 'package:labsvpn/core/http_client/dio_http_client.dart';
import 'package:labsvpn/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_client_provider.g.dart';

@Riverpod(keepAlive: true)
DioHttpClient httpClient(Ref ref) {
  final client = DioHttpClient(
    // 20s balance between slow mobile networks and fast feedback
    timeout: const Duration(seconds: 20),
    userAgent: ref.watch(appInfoProvider).requireValue.userAgent,
    debug: kDebugMode,
  );

  ref.listen(ConfigOptions.mixedPort, (_, next) => client.setProxyPort(next), fireImmediately: true);
  return client;
}
