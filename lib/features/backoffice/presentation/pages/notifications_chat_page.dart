import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/providers.dart';
import '../../domain/communication_state.dart';

class NotificationsChatPage extends ConsumerStatefulWidget {
  const NotificationsChatPage({super.key});

  @override
  ConsumerState<NotificationsChatPage> createState() =>
      _NotificationsChatPageState();
}

class _NotificationsChatPageState extends ConsumerState<NotificationsChatPage> {
  final TextEditingController _messageController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(int conversationIndex) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.period.name.toUpperCase()}';

    ref.read(chatMessagesProvider.notifier).update((state) {
      final existing = List<Map<String, dynamic>>.from(state[conversationIndex] ?? []);
      existing.add({'text': text, 'isOutbound': true, 'time': timeStr});
      return {...state, conversationIndex: existing};
    });

    // Mark conversation as read
    ref.read(unreadConversationsProvider.notifier).update(
          (s) => s.difference({conversationIndex}),
        );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedChatIndexProvider);
    final unread = ref.watch(unreadConversationsProvider);
    final callState = ref.watch(activeCallStateProvider);

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Conversations
            _buildConversationsColumn(selectedIndex, unread),
            // Right Column: Chat Thread
            Expanded(
              child: _buildChatThread(selectedIndex),
            ),
          ],
        ),
        if (callState.status != CallStatus.idle)
          _buildCallOverlay(callState),
      ],
    );
  }

  Widget _buildConversationsColumn(int selectedIndex, Set<int> unread) {
    final conversations = _getMockConversations();
    final filteredConversations = conversations.where((chat) {
      final name = (chat['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

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
                const Text(
                  'Notifications &\nCommunication',
                  style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.2),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search investigators...',
                            hintStyle:
                                TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredConversations.length,
              itemBuilder: (context, index) {
                final chat = filteredConversations[index];
                final originalIndex = chat['originalIndex'] as int;
                return _buildConversationCard(
                    chat, originalIndex == selectedIndex, originalIndex, unread.contains(originalIndex));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
      Map<String, dynamic> chat, bool isSelected, int index, bool isUnread) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedChatIndexProvider.notifier).state = index;
        // Mark as read
        ref.read(unreadConversationsProvider.notifier).update(
              (s) => s.difference({index}),
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: Color(0xFF1E3A8A), width: 4))
              : null,
        ),
        child: Row(
          children: [
            _buildAvatar(chat['avatar'] as String,
                chat['statusColor'] as Color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'] as String,
                        style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            chat['time'] as String,
                            style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat['lastMessage'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF334155)
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500),
                  ),
                  if (chat['isPriority'] as bool) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFB91C1C),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high_rounded,
                              color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text('HIGH PRIORITY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildChatThread(int selectedIndex) {
    final chat = _getMockConversations()[selectedIndex];
    final extraMessages =
        ref.watch(chatMessagesProvider)[selectedIndex] ?? [];

    return Column(
      children: [
        _buildChatHeader(chat),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(40),
            children: [
              _buildDateSeparator('TODAY'),
              const SizedBox(height: 32),
              if (chat['isPriority'] as bool) _buildSystemAlert(),
              const SizedBox(height: 32),
              _buildChatBubble(
                  'I\'ve received the alert. I\'m currently on-site but I don\'t have the updated Facility B schematics on my tablet. They were supposed to be pushed in the last sync.',
                  false,
                  '10:15 AM',
                  chat['avatar'] as String),
              const SizedBox(height: 24),
              _buildChatBubble(
                  'Can you verify if the schematics in the central repository match the physical layout? I suspect a discrepancy near the ventilation shaft.',
                  false,
                  '10:17 AM',
                  chat['avatar'] as String),
              const SizedBox(height: 32),
              _buildChatBubble(
                  'Copy that, Sarah. I\'m pulling the master schematics for Facility B now. I\'ll initiate a forced sync to your device once I\'ve confirmed the shaft details.',
                  true,
                  '10:20 AM',
                  ''),
              const SizedBox(height: 12),
              _buildFileAttachment(
                  'Facility_B_Final_v4.pdf', '2.4 MB', 'Uploading...'),
              // Live sent messages
              for (final msg in extraMessages) ...[
                const SizedBox(height: 24),
                _buildChatBubble(
                  msg['text'] as String,
                  msg['isOutbound'] as bool,
                  msg['time'] as String,
                  '',
                ),
              ],
            ],
          ),
        ),
        _buildMessageInput(chat['name'] as String, selectedIndex),
      ],
    );
  }

  Widget _buildChatHeader(Map<String, dynamic> chat) {
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
          _buildAvatar(
              chat['avatar'] as String, chat['statusColor'] as Color),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat['name'] as String,
                    style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                const SizedBox(height: 4),
                const Text(
                    'SENIOR FIELD INVESTIGATOR • ACTIVE NOW',
                    style: TextStyle(
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
                    name: chat['name'] as String,
                    avatar: chat['avatar'] as String,
                    type: CallType.video,
                  );
            },
            icon: const Icon(Icons.videocam_rounded, color: Color(0xFF334155)),
            tooltip: 'Video Call',
          ),
          IconButton(
            onPressed: () {
              ref.read(activeCallStateProvider.notifier).startCall(
                    name: chat['name'] as String,
                    avatar: chat['avatar'] as String,
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

  Widget _buildDateSeparator(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }

  Widget _buildSystemAlert() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, color: Color(0xFFB91C1C), size: 28),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HIGH PRIORITY SYSTEM ALERT',
                    style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                SizedBox(height: 8),
                Text(
                  'Security breach detected in Facility B storage unit. Requesting immediate verification of facility schematics from field personnel.',
                  style: TextStyle(
                      color: Color(0xFF7F1D1D), fontSize: 14, height: 1.5),
                ),
              ],
            ),
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
      String filename, String size, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_rounded,
                    color: Colors.white, size: 24),
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
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('$size • $status',
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildMessageInput(String name, int conversationIndex) {
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
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Color(0xFF64748B))),
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(conversationIndex),
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
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions_outlined,
                    color: Color(0xFF64748B))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(conversationIndex),
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

  List<Map<String, dynamic>> _getMockConversations() {
    final raw = [
      {
        'name': 'Sarah Jenkins',
        'avatar':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=100',
        'statusColor': const Color(0xFFFDE047),
        'lastMessage': 'Critical: Facility B Schematics',
        'time': 'JUST NOW',
        'isPriority': true,
      },
      {
        'name': 'Marcus Chen',
        'avatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=100',
        'statusColor': const Color(0xFF94A3B8),
        'lastMessage': 'Grid calibration complete for S...',
        'time': '14:02 PM',
        'isPriority': false,
      },
      {
        'name': 'Elena Rodriguez',
        'avatar':
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=100',
        'statusColor': const Color(0xFF22C55E),
        'lastMessage': 'Requesting access to vault logs.',
        'time': '09:45 AM',
        'isPriority': false,
      },
      {
        'name': 'David Smith',
        'avatar':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=100',
        'statusColor': const Color(0xFF22C55E),
        'lastMessage': 'The equipment has been disp...',
        'time': 'Yesterday',
        'isPriority': false,
      },
    ];

    for (int i = 0; i < raw.length; i++) {
      raw[i]['originalIndex'] = i;
    }
    return raw;
  }

  // ─── Calling Overlays ────────────────────────────────────────────────────────

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
