import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../offline/offline_sync_service.dart';

/// Interactive UI badge indicating connection and offline sync status.
/// Displays Online, Offline, or Pending actions with one-tap sync capability.
class OfflineSyncIndicator extends ConsumerWidget {
  final bool isCompact;

  const OfflineSyncIndicator({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncProvider);
    final syncNotifier = ref.read(offlineSyncProvider.notifier);

    // Case 1: Active syncing in progress
    if (syncState.isSyncing) {
      if (isCompact) {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60A5FA)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Syncing (${syncState.pendingCount})...',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Case 2: Offline or pending actions in queue
    if (!syncState.isOnline || syncState.pendingCount > 0) {
      final label = syncState.pendingCount > 0
          ? '${syncState.pendingCount} Pending'
          : 'Offline';

      if (isCompact) {
        return InkWell(
          onTap: () => syncNotifier.syncAll(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off,
              size: 14,
              color: Colors.white,
            ),
          ),
        );
      }

      return InkWell(
        onTap: () {
          syncNotifier.syncAll();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                syncState.pendingCount > 0
                    ? 'Syncing ${syncState.pendingCount} offline actions...'
                    : 'Checking network connection...',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF78350F).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 13,
                color: Color(0xFFFBBF24),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFDE68A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.refresh,
                size: 12,
                color: Color(0xFFFBBF24),
              ),
            ],
          ),
        ),
      );
    }

    // Case 3: Online and idle
    if (isCompact) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF10B981),
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 11,
            color: Color(0xFF34D399),
          ),
          SizedBox(width: 5),
          Text(
            'Online',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
