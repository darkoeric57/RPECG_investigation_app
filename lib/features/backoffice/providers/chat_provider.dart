import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

/// Provider that streams all registered users from the Firestore Users collection
final chatUsersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestoreData = ref.watch(firestoreDataProvider);
  return firestoreData.getUsersStream();
});

/// StateProvider holding the currently selected user (contact) profile map
final activeChatUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

/// Provider calculating the unique, alphabetical composite conversation chatId between two users
final activeChatIdProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(userProvider);
  final selectedUser = ref.watch(activeChatUserProvider);
  
  if (currentUser == null || selectedUser == null) return null;
  
  final uid1 = currentUser.uid;
  final uid2 = selectedUser['uid'] as String? ?? '';
  if (uid2.isEmpty) return null;
  
  return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
});

/// StreamProvider that streams chat messages in real-time for the active conversation
final chatMessagesStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final firestoreData = ref.watch(firestoreDataProvider);
  return firestoreData.getMessagesStream(chatId);
});
