import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../supabase/supabase_client.provider.dart';

/// Supported offline action types for IBUILD ERP
enum SyncActionType {
  attendanceSave,
  snagCreate,
  snagUpdate,
  inventoryTransact,
  dprCreate,
  custom,
}

/// Represents a single queued offline mutation
class SyncAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int retryCount;
  String? lastError;

  SyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
        id: json['id'] as String,
        type: SyncActionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SyncActionType.custom,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
        lastError: json['lastError'] as String?,
      );
}

/// Global sync status and state
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    this.lastSyncedAt,
    this.lastError,
  });

  factory SyncState.initial() => const SyncState(
        isOnline: true,
        isSyncing: false,
        pendingCount: 0,
      );

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Engine managing the offline queue, background retry, and FIFO sync
class OfflineSyncService extends StateNotifier<SyncState> {
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance => _instance ??= OfflineSyncService(null, false);

  SupabaseClient? _client;
  final List<SyncAction> _queue = [];
  Timer? _periodicSyncTimer;

  OfflineSyncService([this._client, bool autoPeriodicSync = true]) : super(SyncState.initial()) {
    _instance = this;
    if (autoPeriodicSync) {
      _initPeriodicSync();
    }
  }

  void setClient(SupabaseClient client) {
    _client = client;
  }

  void _initPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_queue.isNotEmpty && !state.isSyncing) {
        syncAll();
      }
    });
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  /// List of currently queued actions
  List<SyncAction> get queue => List.unmodifiable(_queue);

  /// Set connectivity mode manually or via listener
  void setOnline(bool online) {
    if (state.isOnline != online) {
      state = state.copyWith(isOnline: online);
      if (online && _queue.isNotEmpty && !state.isSyncing) {
        syncAll();
      }
    }
  }

  /// Enqueue an action to be executed offline or synced immediately if online
  String enqueueAction({
    required SyncActionType type,
    required Map<String, dynamic> payload,
  }) {
    final actionId = const Uuid().v4();
    final action = SyncAction(
      id: actionId,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );

    _queue.add(action);
    state = state.copyWith(pendingCount: _queue.length);
    debugPrint('[OfflineSync] Enqueued action: ${type.name} (id: $actionId). Total pending: ${_queue.length}');

    // If online, attempt to process immediately
    if (state.isOnline && !state.isSyncing) {
      syncAll();
    }

    return actionId;
  }

  /// Process all queued actions against Supabase in FIFO order
  Future<int> syncAll() async {
    if (_queue.isEmpty || state.isSyncing) return 0;
    if (_client == null) {
      debugPrint('[OfflineSync] No Supabase client configured for sync.');
      return 0;
    }

    state = state.copyWith(isSyncing: true, clearError: true);
    int syncedCount = 0;

    final actionsToProcess = List<SyncAction>.from(_queue);

    for (final action in actionsToProcess) {
      try {
        final success = await _dispatchAction(action, _client!);
        if (success) {
          _queue.removeWhere((a) => a.id == action.id);
          syncedCount++;
          debugPrint('[OfflineSync] Successfully synced ${action.type.name} (id: ${action.id})');
        } else {
          action.retryCount++;
          action.lastError = 'Server returned unsuccessful response';
        }
      } catch (e) {
        action.retryCount++;
        action.lastError = e.toString();
        debugPrint('[OfflineSync] Failed to sync ${action.type.name} (attempt ${action.retryCount}): $e');
        
        // If network error occurred, mark offline
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('ClientException') ||
            e.toString().contains('TimeoutException')) {
          state = state.copyWith(isOnline: false);
          break; // Stop loop until connectivity returns
        }
      }
    }

    state = state.copyWith(
      isSyncing: false,
      pendingCount: _queue.length,
      lastSyncedAt: syncedCount > 0 ? DateTime.now() : state.lastSyncedAt,
      lastError: _queue.isNotEmpty ? '${_queue.length} actions pending retry' : null,
    );

    return syncedCount;
  }

  /// Dispatch individual action to appropriate Supabase table
  Future<bool> _dispatchAction(SyncAction action, SupabaseClient client) async {
    final payload = Map<String, dynamic>.from(action.payload);

    switch (action.type) {
      case SyncActionType.attendanceSave:
        final employeeId = payload['employee_id'] as String?;
        final date = payload['date'] as String?;
        if (employeeId == null || date == null) return true; // invalid, discard

        // Check if existing record exists
        final existing = await client
            .from('attendance')
            .select('id')
            .eq('employee_id', employeeId)
            .eq('date', date);

        if ((existing as List).isNotEmpty) {
          final id = existing.first['id'] as String;
          await client.from('attendance').update(payload).eq('id', id);
        } else {
          await client.from('attendance').insert(payload);
        }
        return true;

      case SyncActionType.snagCreate:
        await client.from('snags').insert(payload);
        return true;

      case SyncActionType.snagUpdate:
        final id = payload.remove('id') as String?;
        if (id == null) return true;
        await client.from('snags').update(payload).eq('id', id);
        return true;

      case SyncActionType.inventoryTransact:
        await client.from('inventory_history').insert(payload);
        return true;

      case SyncActionType.dprCreate:
        await client.from('daily_progress').insert(payload);
        return true;

      case SyncActionType.custom:
        final table = payload.remove('_table') as String? ?? 'audit_logs';
        await client.from(table).insert(payload);
        return true;
    }
  }

  /// Remove a specific action from the queue
  void removeAction(String actionId) {
    _queue.removeWhere((a) => a.id == actionId);
    state = state.copyWith(pendingCount: _queue.length);
  }

  /// Clear all queued actions
  void clearQueue() {
    _queue.clear();
    state = state.copyWith(pendingCount: 0);
  }
}

/// Global provider for offline sync service
final offlineSyncProvider =
    StateNotifierProvider<OfflineSyncService, SyncState>((ref) {
  SupabaseClient? client;
  try {
    client = ref.watch(supabaseClientProvider);
  } catch (_) {}
  return OfflineSyncService(client);
});
