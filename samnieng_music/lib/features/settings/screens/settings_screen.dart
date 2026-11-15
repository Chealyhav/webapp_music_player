import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:samnieng_music/core/constants/app_colors.dart';
import 'package:samnieng_music/core/utils/audio_logger.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogsViewer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final recentLogs = AudioLogger.recentLogs;
          final recentErrors = AudioLogger.recentErrors;

          return SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Audio & Error Logs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
                            tooltip: 'Clear Logs',
                            onPressed: () {
                              AudioLogger.clearLogs();
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.surfaceVariant),
                  Text(
                    'Track Errors: ${recentErrors.length} | Total Logs: ${recentLogs.length}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: recentLogs.isEmpty
                        ? const Center(
                            child: Text(
                              'No logs or errors recorded yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            itemCount: recentLogs.length,
                            itemBuilder: (c, idx) {
                              final log = recentLogs[recentLogs.length - 1 - idx];
                              Color logColor = AppColors.textSecondary;
                              if (log.level == AudioLogLevel.error) {
                                logColor = AppColors.error;
                              } else if (log.level == AudioLogLevel.warning) {
                                logColor = AppColors.warning;
                              } else if (log.tag.contains('SUCCESS')) {
                                logColor = AppColors.success;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '[${log.category.name.toUpperCase()}] ${log.tag}',
                                          style: TextStyle(
                                            color: logColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      log.message,
                                      style: TextStyle(color: logColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Dark Mode'),
            trailing: Switch(value: true, onChanged: null),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: AppColors.warning),
            title: const Text('Audio Playback & Error Logs'),
            subtitle: const Text('View convert audio and track error history'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLogsViewer(context),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
