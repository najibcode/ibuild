import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

/// Wraps a child widget and only renders it if the user has the required permission.
///
/// Usage:
/// ```dart
/// PermissionGuard(
///   permission: 'employee.delete',
///   child: IconButton(onPressed: _delete, icon: Icon(Icons.delete)),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  /// The permission key to check, e.g. 'employee.create'.
  final String permission;

  /// The widget to show if permission is granted.
  final Widget child;

  /// Optional widget to show if permission is denied.
  /// Defaults to an empty box (hidden).
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    if (hasPermission) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Shows an "Access Denied" card as fallback — useful for full-screen guards.
class AccessDeniedCard extends StatelessWidget {
  final String? message;

  const AccessDeniedCard({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'You do not have permission to access this section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
