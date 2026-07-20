import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/activities/data/models/activity_model.dart';
import '../../features/activities/data/repositories/supabase_activity_repository.dart';
import '../theme/app_colors.dart';

class NotificationsDropdown extends ConsumerStatefulWidget {
  const NotificationsDropdown({super.key});

  @override
  ConsumerState<NotificationsDropdown> createState() => _NotificationsDropdownState();
}

class _NotificationsDropdownState extends ConsumerState<NotificationsDropdown> {
  final MenuController _menuController = MenuController();
  List<Activity> _notifications = [];
  bool _isLoading = false;

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(activityRepositoryProvider);
      final notifications = await repo.getNotificationsForUser();
      setState(() => _notifications = notifications);
    } catch (e) {
      print('Failed to load notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      onOpen: _fetchNotifications,
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surfaceWhite),
        elevation: const WidgetStatePropertyAll(8.0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        _fetchNotifications();
                      },
                      child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No new notifications',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      String type = 'Activity';
                      IconData icon = Icons.info_outline;
                      Color iconColor = AppColors.primary;

                      if (n.actionType.contains('created') || n.actionType.contains('added')) {
                        type = 'Added';
                        icon = Icons.add_circle_outline;
                        iconColor = const Color(0xFF4CAF50);
                      } else if (n.actionType.contains('updated')) {
                        type = 'Updated';
                        icon = Icons.edit_outlined;
                        iconColor = const Color(0xFF2196F3);
                      } else if (n.actionType.contains('deleted') || n.actionType.contains('archived')) {
                        type = 'Removed';
                        icon = Icons.remove_circle_outline;
                        iconColor = const Color(0xFFF44336);
                      } else if (n.actionType.startsWith('inventory_')) {
                        type = 'Inventory';
                        icon = Icons.inventory_2_outlined;
                        iconColor = const Color(0xFFFF9800);
                      }

                      // Build detail text from action details
                      String detail = '';
                      if (n.details.containsKey('name')) {
                        detail = '${n.details['name']}';
                      } else if (n.details.containsKey('item_name')) {
                        detail = '${n.details['item_name']}';
                      } else if (n.details.containsKey('bill_number')) {
                        detail = '#${n.details['bill_number']}';
                      } else if (n.details.containsKey('morning_status')) {
                        final empName = n.details['employee_name'] ?? '';
                        detail = '$empName: ${n.details['morning_status']}';
                      } else if (n.details.containsKey('progress_percentage')) {
                        detail = '${n.details['progress_percentage']}% complete';
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.1),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        title: Text(
                          '$type ${n.entityType}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: const TextStyle(color: AppColors.textMain, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              'By ${n.userName ?? "Unknown"} • ${_timeAgo(n.createdAt)}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                        isThreeLine: detail.isNotEmpty,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
      child: IconButton(
        icon: const Icon(Icons.notifications_none, color: AppColors.outline, size: 20),
        tooltip: 'Notifications',
        onPressed: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
