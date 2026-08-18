import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/core/theme/app_colors.dart';
import 'package:ibuild/features/admin/data/models/audit_log_model.dart';
import 'package:ibuild/features/admin/presentation/providers/admin_providers.dart';

class AdminAuditLogTab extends ConsumerWidget {
  const AdminAuditLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(auditLogsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Control Bar ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECURITY & GOVERNANCE AUDIT TRAIL',
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedText,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Immutable log of all administrative actions and security events',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Audit Logs',
                  onPressed: () => ref.invalidate(auditLogsProvider),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Filter Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(context, ref, 'all', 'All Events'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, 'user.created', 'User Created'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, 'role.changed', 'Role Changes'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, 'user.disabled', 'Access Disabled'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, 'password.reset_by_admin', 'Password Updates'),
                  const SizedBox(width: 8),
                  _filterChip(context, ref, 'settings.updated', 'Settings Changes'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Audit Logs List ──
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_edu_outlined, size: 48, color: mutedText),
                        const SizedBox(height: 12),
                        Text(
                          'No audit events recorded yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administrative actions like user creation, role changes, and settings updates will appear here automatically.',
                          style: TextStyle(color: mutedText, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _auditLogTile(context, log);
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Failed to load audit logs: $e', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext context, WidgetRef ref, String actionKey, String label) {
    final active = ref.watch(auditLogActionFilterProvider);
    final isSelected = active == actionKey;
    final primaryColor = AppColors.primaryColor(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(auditLogActionFilterProvider.notifier).state = actionKey,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : AppColors.mutedText(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: AppColors.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? primaryColor : AppColors.border(context),
        ),
      ),
    );
  }

  Widget _auditLogTile(BuildContext context, AuditLogEntry log) {
    final cardBg = AppColors.cardBg(context);
    final borderCol = AppColors.border(context);
    final mutedText = AppColors.mutedText(context);

    IconData icon;
    Color color;

    if (log.action.contains('create')) {
      icon = Icons.person_add;
      color = Colors.green;
    } else if (log.action.contains('role')) {
      icon = Icons.shield_outlined;
      color = Colors.blueAccent;
    } else if (log.action.contains('disabled')) {
      icon = Icons.block;
      color = Colors.redAccent;
    } else if (log.action.contains('password')) {
      icon = Icons.key;
      color = Colors.orange;
    } else if (log.action.contains('settings') || log.action.contains('branding')) {
      icon = Icons.tune;
      color = Colors.purpleAccent;
    } else {
      icon = Icons.circle_outlined;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.actionTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text(context),
                      ),
                    ),
                    Text(
                      _formatRelativeTime(log.createdAt),
                      style: TextStyle(color: mutedText, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Initiated by ${log.actorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (log.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderCol.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDetails(log.details),
                      style: TextStyle(fontSize: 11, color: mutedText, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetails(Map<String, dynamic> details) {
    return details.entries.map((e) => '${e.key}: ${e.value}').join('  •  ');
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
