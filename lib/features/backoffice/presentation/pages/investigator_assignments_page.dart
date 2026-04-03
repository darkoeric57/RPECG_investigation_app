import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/dashboard/domain/investigator.dart';

class InvestigatorAssignmentsPage extends ConsumerWidget {
  const InvestigatorAssignmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investigatorsAsync = ref.watch(backofficeInvestigatorsProvider);
    final showOnlyAvailable = ref.watch(showOnlyAvailableProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column 1: Pending Tasks
                Expanded(
                  flex: 3,
                  child: _buildPendingTasksColumn(),
                ),
              const SizedBox(width: 48),
              // Column 2 & 3: Field Investigators
              Expanded(
                flex: 7,
                child: investigatorsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (investigators) {
                    final all = investigators.isEmpty ? _getMockInvestigators() : investigators;
                    final displayList = showOnlyAvailable
                        ? all.where((i) => i.status == InvestigatorStatus.online).toList()
                        : all;
                    return _buildInvestigatorsSection(context, ref, displayList, all, showOnlyAvailable);
                  },
                ),
              ),
            ],
          ),
        ),
        ),
        // Bottom Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: investigatorsAsync.when(
            loading: () => _buildBottomBar(context, 0, 0),
            error: (_, __) => _buildBottomBar(context, 0, 0),
            data: (investigators) {
              final all = investigators.isEmpty ? _getMockInvestigators() : investigators;
              final online = all.where((i) => i.status == InvestigatorStatus.online).length;
              return _buildBottomBar(context, online, all.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTasksColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pending Tasks',
              style: TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '12 Active',
                style: TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildTaskCard(
                type: 'INDUSTRIAL METER #882',
                title: 'Structural Integrity Audit',
                desc: 'Urgent inspection required for sector 4-B main conduit following pressur...',
                location: 'North Harbor District',
                deadline: '2h Remaining',
                isUrgent: true,
              ),
              _buildTaskCard(
                type: 'RESIDENTIAL GRID #12',
                title: 'Standard Meter Read',
                desc: 'Routine monthly collection for high-density residential block. 42 units...',
                location: 'Elm St. Complex',
                deadline: 'Routine',
              ),
              _buildTaskCard(
                type: 'UTILITY HUB #A9',
                title: 'Sensor Calibration',
                desc: 'Firmware update and manual calibration of environmental sensor...',
                location: 'Central Substation',
                deadline: 'High Priority',
                isHighPriority: true,
              ),
              _buildTaskCard(
                type: 'PUBLIC SECTOR #04',
                title: 'Damage Assessment',
                desc: 'Post-storm evaluation of external conduit housing on Park View bridge.',
                location: 'Riverside Park',
                deadline: '1 Day',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required String type,
    required String title,
    required String desc,
    required String location,
    required String deadline,
    bool isUrgent = false,
    bool isHighPriority = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isUrgent ? const Color(0xFFB45309) : const Color(0xFFE2E8F0),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(color: Color(0xFF334155), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(
                Icons.access_time,
                size: 16,
                color: isUrgent ? const Color(0xFFB45309) : (isHighPriority ? AppTheme.primary : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
              Text(
                deadline,
                style: TextStyle(
                  color: isUrgent ? const Color(0xFFB45309) : (isHighPriority ? AppTheme.primary : const Color(0xFF334155)),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigatorsSection(BuildContext context, WidgetRef ref, List<Investigator> investigators, List<Investigator> allInvestigators, bool showOnlyAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Field Investigators',
                  style: TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Showing ${investigators.length} of ${allInvestigators.length} investigators',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(showOnlyAvailableProvider.notifier).state = !showOnlyAvailable,
              child: _buildActionSecondary(showOnlyAvailable ? 'Filter: Available ✓' : 'Filter: All'),
            ),
            const SizedBox(width: 12),
            _buildActionSecondary('Map View'),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.82,
                ),
                itemCount: investigators.length,
                itemBuilder: (context, index) {
                  return _buildInvestigatorCard(investigators[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigatorCard(Investigator inv) {
    final bool isAvailable = inv.status == InvestigatorStatus.online;
    final bool isOffDuty = inv.name == 'Sarah Jenkins'; // Mock for design
    final bool isInField = inv.name == 'Jameson Chen'; // Mock for design

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOffDuty ? const Color(0xFFF1F5F9).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(inv.name, isAvailable),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      inv.location,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isInField ? 'IN FIELD' : (isOffDuty ? 'OFF DUTY' : 'AVAILABLE'), isAvailable, isInField),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildAssignmentArea(isInField, isOffDuty),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF166534)),
              const SizedBox(width: 4),
              const Text('98% Score', style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              const Icon(Icons.directions_car, size: 16, color: Color(0xFF334155)),
              const SizedBox(width: 4),
              const Text('Mobile', style: TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, bool active) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage('https://ui-avatars.com/api/?name=$name&background=random'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, bool isAvailable, bool isInField) {
    final bgColor = isInField ? const Color(0xFFDBEAFE) : (isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9));
    final textColor = isInField ? const Color(0xFF1E40AF) : (isAvailable ? const Color(0xFF166534) : const Color(0xFF64748B));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildAssignmentArea(bool isInField, bool isOffDuty) {
    if (isOffDuty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'RETURNS 08:00 TOMORROW',
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
          ),
        ),
      );
    }
    if (isInField) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT TASK', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              Text('65% Done', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Main Line Pressure Test', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF94A3B8), size: 32),
            SizedBox(height: 8),
            Text(
              'Drop task here to assign',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSecondary(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int online, int total) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        children: [
          _buildStat('TOTAL ACTIVE PERSONNEL', '$online / $total', const Color(0xFF1E40AF)),
          const SizedBox(width: 48),
          _buildStat('TASKS IN QUEUE', '12 Pending', const Color(0xFFB45309)),
          const SizedBox(width: 48),
          _buildStat('EFFICIENCY RATING', '${total > 0 ? ((online / total) * 100).toStringAsFixed(1) : '0.0'}%', const Color(0xFF166534)),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Broadcast alert sent to all active investigators.'), backgroundColor: Colors.orange),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Broadcast Alert', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment log exported.'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Export Assignment Log', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 24),
        ),
      ],
    );
  }

  List<Investigator> _getMockInvestigators() {
    return [
      Investigator(id: '1', name: 'Elena Rodriguez', location: 'Senior Technician | District 4', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '2', name: 'Jameson Chen', location: 'Field Analyst | District 1', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '3', name: 'Marcus Vance', location: 'Lead Inspector | District 7', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '4', name: 'Sarah Jenkins', location: 'Field Technician | District 2', imageUrl: '', status: InvestigatorStatus.offline),
    ];
  }
}
