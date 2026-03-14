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
    // We can't watch the metersProvider here directly as it's a FutureProvider
    // Instead we will refresh and count manually when needed or on init
    _updateUnsyncedCount();
    return SyncState();
  }

  Future<void> _updateUnsyncedCount() async {
    final meters = await ref.read(meterRepositoryProvider).getMeters();
    final count = meters.where((m) => !m.isSynced).length;
    state = state.copyWith(unsyncedCount: count);
  }

  Future<void> performSync() async {
    if (state.isSyncing || state.unsyncedCount == 0) return;

    state = state.copyWith(isSyncing: true);
    
    try {
      await ref.read(meterRepositoryProvider).syncMeters();
      
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
  
  // Method to be called after adding a meter
  void notifyNewMeterAdded() {
    _updateUnsyncedCount();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
