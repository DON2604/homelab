import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelab_mobile/core/theme/app_theme.dart';
import 'package:homelab_mobile/features/gallery/presentation/providers/logs_provider.dart';

class LogsDrawer extends ConsumerWidget {
  const LogsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset('assets/dev.gif', width: 36, height: 36),
                  const SizedBox(width: 4),
                  Text(
                    'Server Logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh Logs',
                    onPressed: () => ref.refresh(logsProvider),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('No logs available.'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12.0),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant.withAlpha(100),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Text(
                          logs[index],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: AppTheme.onSurface,
                              ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading logs:\n$err',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
