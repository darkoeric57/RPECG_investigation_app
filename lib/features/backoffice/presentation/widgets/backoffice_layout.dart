import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backoffice_sidebar.dart';
import 'backoffice_topbar.dart';
import '../providers/backoffice_providers.dart';

// Placeholder Pages
import '../pages/dashboard_page.dart';
import '../pages/data_management_page.dart';
import '../pages/investigator_assignments_page.dart';
import '../pages/field_reports_page.dart';
import '../pages/notifications_chat_page.dart';
import '../pages/map_view_page.dart';
import '../pages/settings_page.dart';
import '../pages/billing_dashboard_page.dart';
import '../pages/meter_details_summary_page.dart';

class BackofficeLayout extends ConsumerWidget {
  const BackofficeLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(backofficePageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Material( // Added Material context for web stability
        color: const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Row(
            children: [
              const BackofficeSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const BackofficeTopBar(),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0xFFF8FAFC),
                        child: _buildPage(currentPage),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BackofficePage page) {
    try {
      switch (page) {
        case BackofficePage.dashboard:
          return const DashboardPage();
        case BackofficePage.dataManagement:
          return const DataManagementPage();
        case BackofficePage.investigatorAssignments:
          return const InvestigatorAssignmentsPage();
        case BackofficePage.fieldReports:
          return const FieldReportsPage();
        case BackofficePage.notificationsChat:
          return const NotificationsChatPage();
        case BackofficePage.mapView:
          return const MapViewPage();
        case BackofficePage.settings:
          return const SettingsPage();
        case BackofficePage.billingDashboard:
          return const BillingDashboardPage();
        case BackofficePage.meterDetails:
          return const MeterDetailsSummaryPage();
      }
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text('Error loading page: $e'),
          ],
        ),
      );
    }
  }
}
