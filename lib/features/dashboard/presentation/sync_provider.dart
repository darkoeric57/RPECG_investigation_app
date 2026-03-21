import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

class SyncState {
  final bool isSyncing;
  final int unsyncedCount;
  final String? lastSyncTime;

  SyncState({
    this.isSyncing = false,
    this.unsyncedCount = 0,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? unsyncedCount,
    String? lastSyncTime,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    // Initial data pull and count update
    _initialSync();
    return SyncState();
  }

  Future<void> _initialSync() async {
    await ref.read(meterRepositoryProvider).pullMeters();
    _updateUnsyncedCount();
    ref.invalidate(metersProvider);
  }

  Future<void> _updateUnsyncedCount() async {
    final meters = await ref.read(meterRepositoryProvider).getMeters();
    final count = meters.where((m) => !m.isSynced).length;
    state = state.copyWith(unsyncedCount: count);
  }

  Future<void> performSync() async {
    if (state.isSyncing) return;
    
    // We pull first to get new remote changes, then push local changes

    state = state.copyWith(isSyncing: true);
    
    try {
      final repo = ref.read(meterRepositoryProvider);
      
      // Pull remote data
      await repo.pullMeters();
      
      // Sync local data to remote
      await repo.syncMeters();
      
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      
      state = state.copyWith(
        isSyncing: false,
        unsyncedCount: 0,
        lastSyncTime: timeStr,
      );
      
      // Refresh the meters provider so UI updates
      ref.invalidate(metersProvider);
      ref.invalidate(searchedMetersProvider);
    } catch (e) {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> forcePull() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true);
    try {
      await ref.read(meterRepositoryProvider).pullMeters();
      _updateUnsyncedCount();
      ref.invalidate(metersProvider);
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(isSyncing: false);
    }
  }
  
  // Method to be called after adding a meter
  void notifyNewMeterAdded() {
    _updateUnsyncedCount();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
