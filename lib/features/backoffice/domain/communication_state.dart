import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Notification Models & Providers ─────────────────────────────────────────

enum NotificationPriority { info, warning, critical }

class AppNotification {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPriority priority;

  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    required this.priority,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    NotificationPriority? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
    );
  }
}

class NotificationsListNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsListNotifier()
      : super([
          AppNotification(
            id: '1',
            title: 'Critical System Alert',
            content: 'Security breach detected in Facility B storage unit. Schematics verification required.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            priority: NotificationPriority.critical,
          ),
          AppNotification(
            id: '2',
            title: 'Grid Mismatch Detected',
            content: 'New Excel ledger import indicates 2 mismatching meter/account mappings in Sector 4.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            priority: NotificationPriority.warning,
          ),
          AppNotification(
            id: '3',
            title: 'Sarah Jenkins',
            content: 'Sent you an updated schematic drawing: Facility_B_Final_v4.pdf (2.4 MB).',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            priority: NotificationPriority.info,
          ),
        ]);

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsListProvider =
    StateNotifierProvider<NotificationsListNotifier, List<AppNotification>>((ref) {
  return NotificationsListNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsListProvider);
  return list.where((n) => !n.isRead).length;
});

// ─── Call State Models & Providers ───────────────────────────────────────────

enum CallStatus { idle, ringing, connected }
enum CallType { audio, video }

class CallState {
  final CallStatus status;
  final CallType? type;
  final String? contactName;
  final String? contactAvatar;
  final int durationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;

  CallState({
    this.status = CallStatus.idle,
    this.type,
    this.contactName,
    this.contactAvatar,
    this.durationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
  });

  CallState copyWith({
    CallStatus? status,
    CallType? type,
    String? contactName,
    String? contactAvatar,
    int? durationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOff,
  }) {
    return CallState(
      status: status ?? this.status,
      type: type ?? this.type,
      contactName: contactName ?? this.contactName,
      contactAvatar: contactAvatar ?? this.contactAvatar,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOff: isCameraOff ?? this.isCameraOff,
    );
  }
}

class ActiveCallNotifier extends StateNotifier<CallState> {
  ActiveCallNotifier() : super(CallState());

  Timer? _timer;

  void startCall({
    required String name,
    required String avatar,
    required CallType type,
  }) {
    _timer?.cancel();
    state = CallState(
      status: CallStatus.ringing,
      type: type,
      contactName: name,
      contactAvatar: avatar,
      durationSeconds: 0,
    );

    // Simulate connection after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (state.status == CallStatus.ringing) {
        connectCall();
      }
    });
  }

  void connectCall() {
    state = state.copyWith(status: CallStatus.connected);
    _startTimer();
  }

  void endCall() {
    _timer?.cancel();
    state = CallState(status: CallStatus.idle);
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOff: !state.isCameraOff);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(durationSeconds: state.durationSeconds + 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeCallStateProvider =
    StateNotifierProvider<ActiveCallNotifier, CallState>((ref) {
  return ActiveCallNotifier();
});
