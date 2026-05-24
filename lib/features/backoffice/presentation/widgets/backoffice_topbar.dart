import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers.dart';
import '../providers/backoffice_providers.dart';
import '../../domain/communication_state.dart';

class BackofficeTopBar extends ConsumerWidget {
  const BackofficeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final currentPage = ref.watch(backofficePageProvider);

    final String userName = user?.displayName ?? _extractNameFromEmail(user?.email);

    // Extract account type for the profile section
    final String rawAccountType = 'Staff';
    final String accountType =
        rawAccountType.isNotEmpty && rawAccountType.toUpperCase() != 'DEFAULT'
            ? rawAccountType
            : 'Staff';

    final String initials = _getInitials(userName);

    String getPageTitle(BackofficePage page) => switch (page) {
        BackofficePage.dashboard => 'Overview',
        BackofficePage.dataManagement => 'Import Data',
        BackofficePage.investigatorAssignments => 'Investigators',
        BackofficePage.fieldReports => 'Reports',
        BackofficePage.notificationsChat => 'Chats',
        BackofficePage.mapView => 'Map View',
        BackofficePage.settings => 'Settings',
        BackofficePage.billingDashboard => 'Billing Intelligence',
        BackofficePage.meterDetails => 'Investigation Summary',
        BackofficePage.editInvestigation => 'Edit Investigation',
        BackofficePage.billingAccountDetails => 'Account Details',
        BackofficePage.billingEditAccount => 'Edit Billing Account',
        BackofficePage.billingStatusHistory => 'Status History',
        BackofficePage.billingSchedule => 'Schedule Payment Date',
        BackofficePage.analyticalReports => 'Analytical Reports',
        BackofficePage.revenueAnalysisReport => 'Revenue Analysis Report',
        BackofficePage.consumptionReport => 'Consumption Analysis Report',
        BackofficePage.tariffActivityReport => 'Tariff Activity Analysis Report',
      };

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Simplified title
          Text(
            getPageTitle(currentPage),
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 32),

          // Search bar (hidden on billing dashboard as it's moved to the activity card)
          Expanded(
            child: currentPage == BackofficePage.billingDashboard
                ? const SizedBox.shrink()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search investigators, reports, or meters...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 24),

          _NotificationBell(),
          const SizedBox(width: 24),

          _UserProfileSection(
            userName: userName,
            roleLabel: accountType,
            initials: initials,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _extractNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'Unknown User';
    final local = email.split('@').first;
    return local
        .split(RegExp(r'[._\-]'))
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─── Notification Bell & Dropdown Tray ───────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<void>(
        offset: const Offset(-338, 50),
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        color: Colors.white,
        padding: EdgeInsets.zero,
        itemBuilder: (context) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: const _NotificationTray(),
          ),
        ],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF1E3A8A), size: 22),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTray extends ConsumerWidget {
  const _NotificationTray();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(notificationsListProvider.notifier).markAllAsRead();
                  },
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return _NotificationItemRow(item: item);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationItemRow extends ConsumerWidget {
  final AppNotification item;
  const _NotificationItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color iconColor;
    IconData iconData;
    Color bgColor;

    switch (item.priority) {
      case NotificationPriority.critical:
        iconColor = const Color(0xFFEF4444);
        iconData = Icons.warning_rounded;
        bgColor = const Color(0xFFFEF2F2);
        break;
      case NotificationPriority.warning:
        iconColor = const Color(0xFFF59E0B);
        iconData = Icons.warning_amber_rounded;
        bgColor = const Color(0xFFFEF3C7);
        break;
      case NotificationPriority.info:
        iconColor = const Color(0xFF3B82F6);
        iconData = Icons.info_outline_rounded;
        bgColor = const Color(0xFFEFF6FF);
        break;
    }

    return InkWell(
      onTap: () {
        ref.read(notificationsListProvider.notifier).markAsRead(item.id);
      },
      child: Container(
        color: item.isRead ? Colors.transparent : const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isRead ? FontWeight.bold : FontWeight.w900,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w600,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimeAgo(item.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    return DateFormat('dd MMM').format(dt).toUpperCase();
  }
}

// ─── User Profile Section ─────────────────────────────────────────────────────

class _UserProfileSection extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final String initials;

  const _UserProfileSection({
    required this.userName,
    required this.roleLabel,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              userName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              roleLabel,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
