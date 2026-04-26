import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gap/gap.dart';
import 'package:labsvpn/core/localization/translations.dart';
import 'package:labsvpn/core/model/failures.dart';
import 'package:labsvpn/core/preferences/general_preferences.dart';
import 'package:labsvpn/features/log/data/log_data_providers.dart';
import 'package:labsvpn/features/log/model/log_level.dart';
import 'package:labsvpn/features/log/overview/logs_overview_notifier.dart';
import 'package:labsvpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class LogsPage extends HookConsumerWidget with PresLogger {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final state = ref.watch(logsOverviewNotifierProvider);
    final notifier = ref.watch(logsOverviewNotifierProvider.notifier);
    final filterController = useTextEditingController(text: state.filter);
    final debug = ref.watch(debugModeNotifierProvider);
    final pathResolver = ref.watch(logPathResolverProvider);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, top: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Row(children: [
                      Icon(Icons.arrow_back, size: 18, color: iconColor),
                      const Gap(4),
                      Text('Назад', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: iconColor)),
                    ]),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: state.paused ? notifier.resume : notifier.pause,
                    icon: Icon(state.paused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 22, color: iconColor),
                  ),
                  IconButton(
                    onPressed: notifier.clear,
                    icon: Icon(Icons.delete_outline_rounded, size: 22, color: iconColor),
                  ),
                  if (debug || PlatformUtils.isDesktop)
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, size: 22, color: iconColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        PopupMenuItem(child: Text(t.pages.logs.shareCoreLogs), onTap: () async => await UriUtils.tryShareOrLaunchFile(Uri.parse(pathResolver.coreFile().path), fileOrDir: pathResolver.directory.uri)),
                        PopupMenuItem(child: Text(t.pages.logs.shareAppLogs), onTap: () async => await UriUtils.tryShareOrLaunchFile(Uri.parse(pathResolver.appFile().path), fileOrDir: pathResolver.directory.uri)),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Логи', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
            ),
            const Gap(8),

            // Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: filterController,
                      onChanged: notifier.filterMessage,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Фильтр...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Option<LogLevel>>(
                        value: optionOf(state.levelFilter),
                        onChanged: (v) { if (v != null) notifier.filterLevel(v.toNullable()); },
                        borderRadius: BorderRadius.circular(12),
                        items: [
                          DropdownMenuItem(value: none(), child: const Text('Все')),
                          ...LogLevel.choices.map((e) => DropdownMenuItem(value: some(e), child: Text(e.name))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),

            // Logs list
            Expanded(
              child: switch (state.logs) {
                AsyncData(value: final logs) => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (log.level != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log.level!.name.toUpperCase(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: log.level!.color, letterSpacing: 0.5),
                                ),
                                if (log.time != null)
                                  Text(log.time!.toString(), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                              ],
                            ),
                          Text(
                            extractMessage(log.message),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
                          ),
                          if (index != 0) Divider(height: 8, color: theme.dividerColor.withValues(alpha: 0.08)),
                        ],
                      ),
                    );
                  },
                ),
                AsyncError(:final error) => Center(child: Text(t.presentShortError(error))),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

String extractMessage(String message) {
  final parts = message.split(' ');
  return parts.length <= 2 ? parts.last : parts.sublist(2).join(' ');
}
