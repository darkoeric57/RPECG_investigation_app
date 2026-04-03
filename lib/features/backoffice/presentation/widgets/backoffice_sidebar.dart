import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/backendless_auth_service.dart';
import '../../../../core/providers.dart';

class BackofficeSidebar extends ConsumerWidget {
  const BackofficeSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(isSidebarCollapsedProvider);
    final currentPage = ref.watch(backofficePageProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCollapsed ? 88 : 260,
      decoration: BoxDecoration(
        color: AppTheme.sidebarBg,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, isCollapsed),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(ref, BackofficePage.dashboard, Icons.grid_view_rounded, 'Dashboard', isCollapsed, currentPage == BackofficePage.dashboard),
                _buildNavItem(ref, BackofficePage.dataManagement, Icons.storage_rounded, 'Data Management', isCollapsed, currentPage == BackofficePage.dataManagement),
                _buildNavItem(ref, BackofficePage.investigatorAssignments, Icons.assignment_ind_rounded, 'Assignments', isCollapsed, currentPage == BackofficePage.investigatorAssignments),
                _buildNavItem(ref, BackofficePage.fieldReports, Icons.description_rounded, 'Field Reports', isCollapsed, currentPage == BackofficePage.fieldReports),
                _buildNavItem(ref, BackofficePage.notificationsChat, Icons.chat_bubble_rounded, 'Messages', isCollapsed, currentPage == BackofficePage.notificationsChat),
                _buildNavItem(ref, BackofficePage.mapView, Icons.map_rounded, 'Live Map', isCollapsed, currentPage == BackofficePage.mapView),
                _buildNavItem(ref, BackofficePage.billingDashboard, Icons.receipt_long_rounded, 'Billing Intelligence', isCollapsed, currentPage == BackofficePage.billingDashboard),
                _buildNavItem(ref, BackofficePage.settings, Icons.settings_rounded, 'Settings', isCollapsed, currentPage == BackofficePage.settings),
              ],
            ),
          ),
          _buildFooter(context, ref, isCollapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCollapsed) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 24),
      alignment: Alignment.centerLeft,
      child: isCollapsed
          ? Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Color(0xFF0F172A), size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SOVEREIGN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'UTILITY',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, BackofficePage page, IconData icon, String label, bool isCollapsed, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(backofficePageProvider.notifier).state = page,
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: isActive ? AppTheme.secondary : Colors.white.withValues(alpha: 0.5),
                    size: 22,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, bool isCollapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFooterItem(
            context,
            ref,
            Icons.help_outline_rounded, 
            'Help Center', 
            isCollapsed,
            onTap: () {},
          ),
          _buildFooterItem(
            context,
            ref,
            Icons.logout_rounded, 
            'Sign Out', 
            isCollapsed,
            onTap: () async {
              final authService = BackendlessAuthService();
              await authService.logout();
              ref.read(userProvider.notifier).state = null;
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 16),
          _buildCollapseButton(ref, isCollapsed),
        ],
      ),
    );
  }

  Widget _buildFooterItem(BuildContext context, WidgetRef ref, IconData icon, String label, bool isCollapsed, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(WidgetRef ref, bool isCollapsed) {
    return InkWell(
      onTap: () => ref.read(isSidebarCollapsedProvider.notifier).state = !isCollapsed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
