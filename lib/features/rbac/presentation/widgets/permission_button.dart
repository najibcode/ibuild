import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibuild/features/rbac/presentation/providers/permission_provider.dart';

/// A button wrapper that disables or hides the button if the user lacks permission.
///
/// Usage:
/// ```dart
/// PermissionButton(
///   permission: 'employee.delete',
///   onPressed: _deleteEmployee,
///   child: Text('Delete'),
///   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
/// )
/// ```
class PermissionButton extends ConsumerWidget {
  final String permission;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  /// If true, hides the button entirely when no permission (default).
  /// If false, shows a disabled/greyed-out button.
  final bool hideWhenDenied;

  const PermissionButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.hideWhenDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    if (!hasPermission && hideWhenDenied) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: hasPermission ? onPressed : null,
      style: style,
      child: child,
    );
  }
}

/// An IconButton variant that respects permissions.
class PermissionIconButton extends ConsumerWidget {
  final String permission;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final bool hideWhenDenied;

  const PermissionIconButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.hideWhenDenied = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    if (!hasPermission && hideWhenDenied) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: hasPermission ? onPressed : null,
      icon: icon,
      tooltip: hasPermission ? tooltip : 'Permission denied',
    );
  }
}
