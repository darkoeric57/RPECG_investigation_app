import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/providers.dart';
import '../../domain/communication_state.dart';
import '../../providers/chat_provider.dart';
import '../../../../core/services/firebase_data_service.dart';

class NotificationsChatPage extends ConsumerStatefulWidget {
  const NotificationsChatPage({super.key});

  @override
  ConsumerState<NotificationsChatPage> createState() =>
      _NotificationsChatPageState();
}

class _NotificationsChatPageState extends ConsumerState<NotificationsChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchExpanded = false;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider);
      if (currentUser != null) {
        FirestoreDataService().seedMockUsers(currentUser.uid);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _sendMessage(String chatId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(userProvider);
    if (currentUser != null) {
      FirestoreDataService().saveMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Manager',
        text: text,
        type: 'text',
      );
    }
    _messageController.clear();
  }

  void _sendVoiceNote(String chatId) {
    _recordTimer?.cancel();
    final mins = (_recordSeconds / 60).floor().toString();
    final secs = (_recordSeconds % 60).toString().padLeft(2, '0');
    final durationStr = '$mins:$secs';

    final currentUser = ref.read(userProvider);
    if (currentUser != null) {
      FirestoreDataService().saveMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Manager',
        text: 'Voice note ($durationStr)',
        type: 'voice_note',
        filename: 'Voice_Note.m4a',
        fileSize: '${(_recordSeconds * 12.5).toStringAsFixed(1)} KB',
        status: 'Delivered',
        voiceDuration: _recordSeconds,
      );
    }

    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _simulateUpload(String chatId, String fileType) {
    String filename = 'Document_Report.pdf';
    String fileSize = '1.4 MB';
    if (fileType == 'audio') {
      filename = 'Audio_Log.mp3';
      fileSize = '3.2 MB';
    } else if (fileType == 'video') {
      filename = 'Video_Capture.mp4';
      fileSize = '12.4 MB';
    }

    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    FirestoreDataService().saveMessage(
      chatId: chatId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'Manager',
      text: 'Sent a $fileType: $filename',
      type: fileType,
      filename: filename,
      fileSize: fileSize,
      status: 'Uploading...',
    );

    Future.delayed(const Duration(milliseconds: 1500), () async {
      try {
        final messages = await FirebaseFirestore.instance
            .collection('Chats')
            .doc(chatId)
            .collection('Messages')
            .where('filename', isEqualTo: filename)
            .where('status', isEqualTo: 'Uploading...')
            .get();
        for (var doc in messages.docs) {
          await doc.reference.update({'status': 'Delivered'});
        }
      } catch (e) {
        print('DEBUG: Error updating upload status: $e');
      }
    });
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordSeconds++;
      });
    });
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }
    
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(unreadConversationsProvider);
    final callState = ref.watch(activeCallStateProvider);

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Conversations
            _buildConversationsColumn(unread),
            // Right Column: Chat Thread
            Expanded(
              child: _buildChatThread(),
            ),
          ],
        ),
        if (callState.status != CallStatus.idle)
          _buildCallOverlay(callState),
      ],
    );
  }

  Widget _buildConversationsColumn(Set<int> unread) {
    final usersAsync = ref.watch(chatUsersStreamProvider);
    final currentUser = ref.watch(userProvider);
    final currentUid = currentUser?.uid ?? '';

    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications &\nCommunication',
                        style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TapRegion(
                      onTapOutside: (event) {
                        if (_searchExpanded && _searchController.text.isEmpty) {
                          setState(() => _searchExpanded = false);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastOutSlowIn,
                        width: _searchExpanded ? 200 : 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _searchExpanded ? Colors.white : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(21),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withValues(alpha: _searchExpanded ? 0.12 : 0.05),
                              blurRadius: _searchExpanded ? 16 : 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 2),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(21),
                                onTap: () {
                                  setState(() {
                                    if (!_searchExpanded) {
                                      _searchExpanded = true;
                                    } else if (_searchController.text.isEmpty) {
                                      _searchExpanded = false;
                                      _searchQuery = '';
                                    }
                                  });
                                },
                                child: SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Icon(
                                    Icons.search_rounded, 
                                    size: 18, 
                                    color: _searchExpanded ? const Color(0xFF1E3A8A) : const Color(0xFF64748B)
                                  ),
                                ),
                              ),
                            ),
                            if (_searchExpanded)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Search by ID or name...',
                                      hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                    ),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACTIVE CONVERSATIONS',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5),
                ),
                if (unread.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFDE047),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${unread.length} NEW',
                      style: const TextStyle(
                          color: Color(0xFF854D0E),
                          fontWeight: FontWeight.w900,
                          fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading contacts', style: TextStyle(color: Colors.red[800], fontSize: 13))),
              data: (allUsers) {
                final contacts = allUsers.where((u) => u['uid'] != currentUid).toList();
                final filtered = contacts.where((chat) {
                  final name = (chat['name'] as String? ?? '').toLowerCase();
                  final staffId = (chat['staffId'] as String? ?? '').toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || staffId.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text('No users match query.',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final chat = filtered[index];
                    final activeUser = ref.watch(activeChatUserProvider);
                    final isSelected = activeUser != null && activeUser['uid'] == chat['uid'];
                    return _buildConversationCard(chat, isSelected, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
      Map<String, dynamic> chat, bool isSelected, int index) {
    final avatar = chat['photoUrl'] as String? ?? 
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=100';
    final statusColor = chat['statusColor'] as Color? ?? const Color(0xFF22C55E);
    final lastMessage = chat['lastMessage'] as String? ?? 'Click to start chatting';
    final timeStr = _formatTimestamp(chat['lastMessageTime']);

    return GestureDetector(
      onTap: () {
        ref.read(activeChatUserProvider.notifier).state = chat;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: const Border(
              bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1)),
        ),
        child: Row(
          children: [
            _buildAvatar(avatar, statusColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'] as String? ?? 'User',
                        style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF334155)
                                  : const Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chat['staffId'] as String? ?? '',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w800,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String url, Color statusColor) {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
                image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            padding: const EdgeInsets.all(3),
            child: Container(
                decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle)),
          ),
        ),
      ],
    );
  }

  Widget _buildChatThread() {
    final targetUser = ref.watch(activeChatUserProvider);
    if (targetUser == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Color(0xFFE2E8F0)),
            SizedBox(height: 24),
            Text('No Conversation Selected',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Select a team member from the list to start chatting in real-time.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    final chatId = ref.watch(activeChatIdProvider) ?? '';
    final messagesAsync = ref.watch(chatMessagesStreamProvider(chatId));

    return Column(
      children: [
        _buildChatHeader(targetUser),
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading messages: $err')),
            data: (messages) {
              final currentUser = ref.watch(userProvider);
              final currentUid = currentUser?.uid ?? '';
              
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      Text('No messages yet with ${targetUser['name']}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Type your first message below to begin.',
                          style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(40),
                itemCount: messages.length,
                itemBuilder: (context, idx) {
                  final msg = messages[idx];
                  final isOutbound = msg['senderId'] == currentUid;
                  final timeStr = _formatTimestamp(msg['timestamp']);

                  if (msg['type'] == 'voice_note') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _VoiceNoteBubble(msg: msg, isOutbound: isOutbound),
                    );
                  } else if (msg['type'] == 'document' || msg['type'] == 'audio' || msg['type'] == 'video') {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildFileAttachment(
                        msg['filename'] as String? ?? 'file',
                        msg['fileSize'] as String? ?? '0 KB',
                        msg['status'] as String? ?? 'Complete',
                        type: msg['type'] as String,
                        isOutbound: isOutbound,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _buildChatBubble(
                        msg['text'] as String? ?? '',
                        isOutbound,
                        timeStr,
                        isOutbound ? '' : (targetUser['photoUrl'] as String? ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=100'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        _buildMessageInput(targetUser['name'] as String? ?? 'User', chatId),
      ],
    );
  }

  Widget _buildChatHeader(Map<String, dynamic> chat) {
    final avatar = chat['photoUrl'] as String? ?? 
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=100';
    final statusColor = chat['statusColor'] as Color? ?? const Color(0xFF22C55E);

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        children: [
          _buildAvatar(avatar, statusColor),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat['name'] as String? ?? 'User',
                    style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 4),
                Text(
                    'STAFF ID: ${chat['staffId'] as String? ?? 'N/A'} • ACTIVE NOW',
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(activeCallStateProvider.notifier).startCall(
                    name: chat['name'] as String? ?? 'User',
                    avatar: avatar,
                    type: CallType.video,
                  );
            },
            icon: const Icon(Icons.videocam_rounded, color: Color(0xFF334155)),
            tooltip: 'Video Call',
          ),
          IconButton(
            onPressed: () {
              ref.read(activeCallStateProvider.notifier).startCall(
                    name: chat['name'] as String? ?? 'User',
                    avatar: avatar,
                    type: CallType.audio,
                  );
            },
            icon: const Icon(Icons.phone_rounded, color: Color(0xFF334155)),
            tooltip: 'Voice Call',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
      String text, bool isOutbound, String time, String avatar) {
    return Row(
      mainAxisAlignment:
          isOutbound ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isOutbound && avatar.isNotEmpty) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                  image: NetworkImage(avatar), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isOutbound
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isOutbound
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft:
                        Radius.circular(isOutbound ? 20 : 4),
                    bottomRight:
                        Radius.circular(isOutbound ? 4 : 20),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                      color: isOutbound
                          ? Colors.white
                          : const Color(0xFF334155),
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                  '$time • ${isOutbound ? 'Read' : 'Delivered'}',
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (isOutbound) ...[
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('ME',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileAttachment(
      String filename, String size, String status, {String type = 'document', bool isOutbound = true}) {
    IconData iconData = Icons.description_rounded;
    Color iconBgColor = Colors.white.withValues(alpha: 0.1);
    Color cardBgColor = const Color(0xFF0F172A);

    if (type == 'audio') {
      iconData = Icons.audiotrack_rounded;
      iconBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
    } else if (type == 'video') {
      iconData = Icons.video_library_rounded;
      iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.2);
    }

    return Row(
      mainAxisAlignment: isOutbound ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isOutbound) ...[
          const SizedBox(width: 48),
        ],
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData,
                    color: type == 'document' ? Colors.white : (type == 'audio' ? const Color(0xFFF59E0B) : const Color(0xFF10B981)), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(filename,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$size • $status',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isOutbound) ...[
          const SizedBox(width: 48),
        ],
      ],
    );
  }

  Widget _buildMessageInput(String name, String chatId) {
    if (_isRecording) {
      final mins = (_recordSeconds / 60).floor().toString();
      final secs = (_recordSeconds % 60).toString().padLeft(2, '0');
      final timeStr = '$mins:$secs';

      return Container(
        padding: const EdgeInsets.all(40),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
          ),
          child: Row(
            children: [
              const _PulsatingRedDot(),
              const SizedBox(width: 12),
              Text(
                'RECORDING VOICE NOTE  •  $timeStr',
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: _AnimatedRecordWaveform()),
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                tooltip: 'Cancel',
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _sendVoiceNote(chatId),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            PopupMenuButton<String>(
              offset: const Offset(0, -160),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF64748B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tooltip: 'Attach File',
              onSelected: (val) => _simulateUpload(chatId, val),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'document',
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 18),
                      SizedBox(width: 12),
                      Text('Upload Document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'audio',
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack_rounded, color: Color(0xFFF59E0B), size: 18),
                      SizedBox(width: 12),
                      Text('Upload Audio File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'video',
                  child: Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 12),
                      Text('Upload Video File', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(chatId),
                decoration: InputDecoration(
                  hintText: 'Type your response to $name...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF64748B)),
              tooltip: 'Record Voice Note',
            ),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Color(0xFF64748B))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(chatId),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Color(0xFFFDE047), shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Color(0xFF854D0E), size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallOverlay(CallState callState) {
    if (callState.type == CallType.audio) {
      return _buildAudioCallOverlay(callState);
    } else {
      return _buildVideoCallOverlay(callState);
    }
  }

  Widget _buildAudioCallOverlay(CallState callState) {
    final minutes = (callState.durationSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (callState.durationSeconds % 60).toString().padLeft(2, '0');
    final timeStr = callState.status == CallStatus.connected ? '$minutes:$seconds' : 'RINGING...';

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsatingAvatar(avatarUrl: callState.contactAvatar ?? ''),
              const SizedBox(height: 48),
              Text(
                callState.contactName ?? 'Senior Investigator',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                timeStr,
                style: TextStyle(
                  color: callState.status == CallStatus.connected ? AppTheme.secondary : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 80),
              // Call action bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRoundCallButton(
                    icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: 'Mute',
                    isActive: callState.isMuted,
                    onTap: () => ref.read(activeCallStateProvider.notifier).toggleMute(),
                  ),
                  const SizedBox(width: 32),
                  _buildRoundCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    bgColor: const Color(0xFFEF4444),
                    iconColor: Colors.white,
                    onTap: () => ref.read(activeCallStateProvider.notifier).endCall(),
                  ),
                  const SizedBox(width: 32),
                  _buildRoundCallButton(
                    icon: callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    label: 'Speaker',
                    isActive: callState.isSpeakerOn,
                    onTap: () => ref.read(activeCallStateProvider.notifier).toggleSpeaker(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCallOverlay(CallState callState) {
    final minutes = (callState.durationSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (callState.durationSeconds % 60).toString().padLeft(2, '0');
    final timeStr = callState.status == CallStatus.connected ? '$minutes:$seconds' : 'CONNECTING...';

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0F172A),
        child: Stack(
          children: [
            // Tech-mesh Background
            const Positioned.fill(
              child: VideoCallGridBackground(),
            ),
            // Simulated HUD Overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FEED: SECURE_LINK_${(callState.contactName ?? '').replaceAll(' ', '_').toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'CRYPTO: AES_256_GCM | LATENCY: 34ms',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE RECORD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Info panel
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              callState.contactName ?? 'Investigator',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        // Glassmorphic control bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: Colors.white.withValues(alpha: 0.05),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildGlassCallButton(
                                    icon: callState.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                                    isActive: !callState.isCameraOff,
                                    onTap: () => ref.read(activeCallStateProvider.notifier).toggleCamera(),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildGlassCallButton(
                                    icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                    isActive: !callState.isMuted,
                                    onTap: () => ref.read(activeCallStateProvider.notifier).toggleMute(),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildGlassCallButton(
                                    icon: Icons.call_end_rounded,
                                    bgColor: const Color(0xFFEF4444),
                                    iconColor: Colors.white,
                                    onTap: () => ref.read(activeCallStateProvider.notifier).endCall(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // PIP Local Preview Thumbnail
            Positioned(
              top: 100,
              right: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 150,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                  ),
                  child: callState.isCameraOff
                      ? const Center(
                          child: Icon(Icons.videocam_off_rounded, color: Color(0xFF64748B), size: 28),
                        )
                      : Stack(
                          children: [
                            // Mock self camera feed (blueprint)
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.3,
                                child: Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: Icon(Icons.person, size: 80, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Text(
                                'Local Cam'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCallButton({
    required IconData icon,
    required String label,
    Color? bgColor,
    Color? iconColor,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final bg = bgColor ?? (isActive ? Colors.white : Colors.white.withValues(alpha: 0.1));
    final fg = iconColor ?? (isActive ? const Color(0xFF0F172A) : Colors.white);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: fg, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildGlassCallButton({
    required IconData icon,
    Color? bgColor,
    Color? iconColor,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final bg = bgColor ?? (isActive ? Colors.white : Colors.white.withValues(alpha: 0.15));
    final fg = iconColor ?? (isActive ? const Color(0xFF0F172A) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: fg, size: 24),
      ),
    );
  }
}

// ─── Pulsating Avatar widget ─────────────────────────────────────────────────

class PulsatingAvatar extends StatefulWidget {
  final String avatarUrl;
  const PulsatingAvatar({super.key, required this.avatarUrl});

  @override
  State<PulsatingAvatar> createState() => _PulsatingAvatarState();
}

class _PulsatingAvatarState extends State<PulsatingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 3; i >= 1; i--)
              Container(
                width: 120 + (_controller.value * i * 50),
                height: 120 + (_controller.value * i * 50),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05 * (4 - i)),
                  shape: BoxShape.circle,
                ),
              ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                image: DecorationImage(
                  image: NetworkImage(widget.avatarUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Video Call Grid Background ──────────────────────────────────────────────

class VideoCallGridBackground extends StatefulWidget {
  const VideoCallGridBackground({super.key});

  @override
  State<VideoCallGridBackground> createState() => _VideoCallGridBackgroundState();
}

class _VideoCallGridBackgroundState extends State<VideoCallGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark Blueprint Background
            Container(color: const Color(0xFF090D16)),
            // Grid Lines Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
            // Scanner Sweep line
            Positioned(
              top: MediaQuery.of(context).size.height * _controller.value,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF0284C7).withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Voice Note player bubble ────────────────────────────────────────────────

class _VoiceNoteBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isOutbound;
  const _VoiceNoteBubble({required this.msg, required this.isOutbound});

  @override
  State<_VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<_VoiceNoteBubble> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _timer;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    final durationStr = widget.msg['audioDuration'] as String? ?? '0:05';
    final parts = durationStr.split(':');
    _totalSeconds = (int.tryParse(parts.first) ?? 0) * 60 + (int.tryParse(parts.last) ?? 5);
    if (_totalSeconds == 0) _totalSeconds = 5;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _progress += 0.1 / _totalSeconds;
          if (_progress >= 1.0) {
            _progress = 0.0;
            _isPlaying = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isOutbound ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9);
    final textColor = widget.isOutbound ? Colors.white : const Color(0xFF334155);
    final iconColor = widget.isOutbound ? const Color(0xFF1E3A8A) : Colors.white;
    final btnBgColor = widget.isOutbound ? Colors.white : const Color(0xFF1E3A8A);

    return Row(
      mainAxisAlignment: widget.isOutbound ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!widget.isOutbound) ...[
          const SizedBox(width: 48), // Align with avatar spacing
        ],
        Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(widget.isOutbound ? 20 : 4),
              bottomRight: Radius.circular(widget.isOutbound ? 4 : 20),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: btnBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(15, (index) {
                        final double fraction = index / 15;
                        final isActive = fraction <= _progress;
                        final height = 4.0 + ((index % 3 == 0 ? 16.0 : (index % 3 == 1 ? 8.0 : 12.0)));
                        return Container(
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: isActive
                                ? (widget.isOutbound ? const Color(0xFFFDE047) : const Color(0xFF1E3A8A))
                                : (widget.isOutbound ? Colors.white.withOpacity(0.3) : const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VOICE NOTE',
                          style: TextStyle(
                            color: widget.isOutbound ? Colors.white.withOpacity(0.6) : const Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          widget.msg['audioDuration'] as String? ?? '0:05',
                          style: TextStyle(
                            color: widget.isOutbound ? Colors.white : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.isOutbound) ...[
          const SizedBox(width: 48),
        ]
      ],
    );
  }
}

// ─── Pulsating Red Dot ───────────────────────────────────────────────────────

class _PulsatingRedDot extends StatefulWidget {
  const _PulsatingRedDot();

  @override
  State<_PulsatingRedDot> createState() => _PulsatingRedDotState();
}

class _PulsatingRedDotState extends State<_PulsatingRedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
      ),
    );
  }
}

// ─── Animated Record Waveform ────────────────────────────────────────────────

class _AnimatedRecordWaveform extends StatefulWidget {
  const _AnimatedRecordWaveform();

  @override
  State<_AnimatedRecordWaveform> createState() => _AnimatedRecordWaveformState();
}

class _AnimatedRecordWaveformState extends State<_AnimatedRecordWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (index) {
            final double phase = (index / 12) * 2 * 3.14159;
            final double sinVal = (1.0 + math.sin(phase + (_controller.value * 2 * 3.14159))) / 2.0;
            final double height = 4.0 + (sinVal * 16.0);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.7),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}



