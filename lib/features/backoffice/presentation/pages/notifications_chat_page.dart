import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/providers.dart';

class NotificationsChatPage extends ConsumerStatefulWidget {
  const NotificationsChatPage({super.key});

  @override
  ConsumerState<NotificationsChatPage> createState() =>
      _NotificationsChatPageState();
}

class _NotificationsChatPageState extends ConsumerState<NotificationsChatPage> {
  final TextEditingController _messageController = TextEditingController();

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Conversations
        _buildConversationsColumn(selectedIndex, unread),
        // Right Column: Chat Thread
        Expanded(
          child: _buildChatThread(selectedIndex),
        ),
      ],
    );
  }

  Widget _buildConversationsColumn(int selectedIndex, Set<int> unread) {
    final conversations = _getMockConversations();
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
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: Color(0xFF94A3B8), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
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
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _buildConversationCard(
                    conversations[index], index == selectedIndex, index, unread.contains(index));
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
    final user = ref.watch(userProvider);
    final senderName = (user?.getProperty('name') as String?) ?? 'You';

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
              onPressed: () {},
              icon: const Icon(Icons.videocam_rounded,
                  color: Color(0xFF334155))),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.phone_rounded, color: Color(0xFF334155))),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFF334155))),
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
                    color: Colors.white.withOpacity(0.1),
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
    return [
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
  }
}
