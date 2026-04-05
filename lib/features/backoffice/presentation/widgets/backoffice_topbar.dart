import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../providers/backoffice_providers.dart';

class BackofficeTopBar extends ConsumerWidget {
  const BackofficeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final currentPage = ref.watch(backofficePageProvider);

    final String userName =
        (user?.getProperty('name') as String?)?.trim().isNotEmpty == true
            ? user!.getProperty('name') as String
            : _extractNameFromEmail(user?.email);

    // Extract account type for the profile section
    final String rawAccountType =
        (user?.getProperty('accountType') as String?)?.trim() ?? '';
    final String accountType =
        rawAccountType.isNotEmpty && rawAccountType.toUpperCase() != 'DEFAULT'
            ? rawAccountType
            : 'Staff';

    final String initials = _getInitials(userName);

    String getPageTitle(BackofficePage page) {
      switch (page) {
        case BackofficePage.dashboard:
          return 'Overview';
        case BackofficePage.dataManagement:
          return 'Import Data';
        case BackofficePage.investigatorAssignments:
          return 'Investigators';
        case BackofficePage.fieldReports:
          return 'Reports';
        case BackofficePage.notificationsChat:
          return 'Chats';
        case BackofficePage.mapView:
          return 'Map View';
        case BackofficePage.settings:
          return 'Settings';
        case BackofficePage.billingDashboard:
          return 'Billing Intelligence';
        case BackofficePage.meterDetails:
          return 'Investigation Summary';
      }
    }

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

          // Search bar
          Expanded(
            child: Center(
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

// ─── Notification Bell ───────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: const Center(
              child: Text('3',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
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
