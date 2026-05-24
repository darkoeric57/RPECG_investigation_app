import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers.dart';

/// Provider that streams all registered users from the Firestore Users collection.
/// Watches userProvider so that whenever the logged-in user changes (e.g. logout/login),
/// the old stream is cancelled and a new stream is established.
final chatUsersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) {
    return const Stream.empty();
  }
  final firestoreData = ref.watch(firestoreDataProvider);
  return firestoreData.getUsersStream();
});

/// StateProvider holding the currently selected user (contact) profile map.
/// Recreates and resets to null whenever the logged-in user changes (e.g. logout/login).
final activeChatUserProvider = StateProvider<Map<String, dynamic>?>((ref) {
  ref.watch(userProvider);
  return null;
});

/// Provider calculating the unique, alphabetical composite conversation chatId between two users.
final activeChatIdProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(userProvider);
  final selectedUser = ref.watch(activeChatUserProvider);
  
  if (currentUser == null || selectedUser == null) return null;
  
  final uid1 = currentUser.uid;
  final uid2 = selectedUser['uid'] as String? ?? '';
  if (uid2.isEmpty) return null;
  
  return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
});

/// StreamProvider that streams chat messages in real-time for the active conversation.
/// Watches userProvider to ensure proper lifetime management across login/logout transitions.
final chatMessagesStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final user = ref.watch(userProvider);
  if (user == null) {
    return const Stream.empty();
  }
  final firestoreData = ref.watch(firestoreDataProvider);
  return firestoreData.getMessagesStream(chatId);
});
