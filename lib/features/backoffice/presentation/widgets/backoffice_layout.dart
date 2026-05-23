import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backoffice_sidebar.dart';
import 'backoffice_topbar.dart';
import 'premium_filter_drawer.dart';
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
import '../pages/edit_investigation_page.dart';
import '../pages/billing_account_details_page.dart';
import '../pages/billing_edit_account_page.dart';
import '../pages/billing_status_history_page.dart';
import '../pages/billing_schedule_page.dart';
import '../pages/billing_analytical_reports_page.dart';
import '../pages/revenue_analysis_report_page.dart';

class BackofficeLayout extends ConsumerWidget {
  const BackofficeLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(backofficePageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      endDrawer: const PremiumFilterDrawer(),
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

  Widget _buildPage(BackofficePage page) => switch (page) {
      BackofficePage.dashboard => const DashboardPage(),
      BackofficePage.dataManagement => const DataManagementPage(),
      BackofficePage.investigatorAssignments => const InvestigatorAssignmentsPage(),
      BackofficePage.fieldReports => const FieldReportsPage(),
      BackofficePage.notificationsChat => const NotificationsChatPage(),
      BackofficePage.mapView => const MapViewPage(),
      BackofficePage.settings => const SettingsPage(),
      BackofficePage.billingDashboard => const BillingDashboardPage(),
      BackofficePage.meterDetails => const MeterDetailsSummaryPage(),
      BackofficePage.editInvestigation => const EditInvestigationPage(),
      BackofficePage.billingAccountDetails => const BillingAccountDetailsPage(),
      BackofficePage.billingEditAccount => const BillingEditAccountPage(),
      BackofficePage.billingStatusHistory => const BillingStatusHistoryPage(),
      BackofficePage.billingSchedule => const BillingSchedulePage(),
      BackofficePage.analyticalReports => const BillingAnalyticalReportsPage(),
      BackofficePage.revenueAnalysisReport => const RevenueAnalysisReportPage(),
    };
}
