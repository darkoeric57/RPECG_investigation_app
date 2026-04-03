import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/utils/web_utils.dart';

class FieldReportsPage extends ConsumerStatefulWidget {
  const FieldReportsPage({super.key});

  @override
  ConsumerState<FieldReportsPage> createState() => _FieldReportsPageState();
}

class _FieldReportsPageState extends ConsumerState<FieldReportsPage> {

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedReportIndexProvider);
    final overrides = ref.watch(reportStatusOverridesProvider);
    final reports = _getMockReports().map((r) {
      final override = overrides[r['id'] as String];
      return override != null ? {...r, 'status': override} : r;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, reports[selectedIndex]),
          const SizedBox(height: 40),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Column: Report List
                Expanded(
                  flex: 3,
                  child: _buildReportList(reports, selectedIndex),
                ),
                const SizedBox(width: 48),
                // Right Column: Report Details
                Expanded(
                  flex: 6,
                  child: _buildReportDetails(context, ref, reports, selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Map<String, dynamic> currentReport) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field Reports',
              style: TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Reviewing active investigation intelligence',
              style: TextStyle(color: const Color(0xFF64748B), fontSize: 16),
            ),
          ],
        ),
        Row(
          children: [
            _buildActionSecondary(Icons.filter_list_rounded, 'Filter'),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                final content = 'Report: ${currentReport['id']}\nTitle: ${currentReport['title']}\nDate: ${currentReport['date']}\nInvestigator: ${currentReport['investigator']}\nStatus: ${currentReport['status']}\n\nNarrative:\n${currentReport['narrative']}';
                WebUtils.downloadFile('${currentReport['id']}_report.txt', content);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report exported.'), backgroundColor: Colors.green),
                );
              },
              child: _buildActionSecondary(Icons.ios_share_rounded, 'Export'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionSecondary(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(List<Map<String, dynamic>> reports, int selectedIndex) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final isSelected = selectedIndex == index;
        return _buildReportCard(report, isSelected, index);
      },
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isSelected, int index) {
    final statusColor = _getStatusColor(report['status'] as String);    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.read(selectedReportIndexProvider.notifier).state = index,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? const Color(0xFFFDE047) : const Color(0xFFE2E8F0),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report['id'],
                        style: const TextStyle(color: Color(0xFF4338CA), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          report['status'],
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  report['title'],
                  style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  report['snippet'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      report['investigator'],
                      style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      report['time'],
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportDetails(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> reports, int selectedIndex) {
    final report = reports[selectedIndex];
    final currentStatus = report['status'] as String;
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report['id']}: ${report['title']}',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(report['date'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(report['time_exact'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (currentStatus != 'Approved')
                  ElevatedButton(
                    onPressed: () {
                      ref.read(reportStatusOverridesProvider.notifier).update(
                        (s) => {...s, report['id'] as String: 'Approved'},
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report approved.'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE047),
                      foregroundColor: const Color(0xFF422006),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Approve Report', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (currentStatus != 'Rejected')
                  const SizedBox(width: 8),
                if (currentStatus != 'Rejected')
                  ElevatedButton(
                    onPressed: () {
                      ref.read(reportStatusOverridesProvider.notifier).update(
                        (s) => {...s, report['id'] as String: 'Rejected'},
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report rejected.'), backgroundColor: Colors.red),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFF991B1B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 12),
                const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(child: _buildMediaCard('PRIMARY INTAKE', report['image1'])),
                const SizedBox(width: 24),
                Expanded(child: _buildMediaCard('THERMAL SCAN', report['image2'])),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(child: _buildMetricCard('METER READING', report['reading'], 'kPa', report['readingProgress'])),
                const SizedBox(width: 20),
                Expanded(child: _buildLocationCard('GPS LOCATION', report['gps'], report['sector'])),
                const SizedBox(width: 20),
                Expanded(child: _buildSignalCard('SIGNAL STRENGTH', report['signal'], report['signalStatus'])),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'INVESTIGATOR NARRATIVE',
              style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                report['narrative'],
                style: const TextStyle(color: Color(0xFF334155), fontSize: 15, height: 1.8),
              ),
            ),
            const SizedBox(height: 40),
            _buildFieldCommunication(report['investigator'], report['unit']),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCommunication(String investigator, String unit) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, color: Color(0xFFFDE047), size: 20),
              const SizedBox(width: 12),
              const Text(
                'FIELD COMMUNICATION',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF450A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF991B1B), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE CONNECT',
                      style: TextStyle(color: Color(0xFFFECACA), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Send a priority update to $investigator...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE047),
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Send Update', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$investigator is currently online via $unit',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(String label, String imageUrl) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String label, String coords, String sector) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFFB45309), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coords, style: const TextStyle(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(sector, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCard(String label, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt_rounded, color: Color(0xFF166534), size: 24),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(status, style: const TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Under Review': return const Color(0xFF1E3A8A);
      case 'Submitted': return const Color(0xFF94A3B8);
      case 'Approved': return const Color(0xFF166534);
      case 'Rejected': return const Color(0xFF991B1B);
      default: return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getMockReports() {
    return [
      {
        'id': 'FR-8829',
        'status': 'Under Review',
        'title': 'Substation Bravo Inspection',
        'snippet': 'Potential casing hairline fracture detected on the primary cooling unit intake pipe...',
        'investigator': 'Sarah Jenkins',
        'time': '2 hours ago',
        'date': 'Oct 24, 2023',
        'time_exact': '14:32 PST',
        'image1': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=600',
        'image2': 'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=600',
        'reading': '428.5',
        'readingProgress': 0.7,
        'gps': '34.0522° N, 118.2437° W',
        'sector': 'Industrial Zone B, Sector 4',
        'signal': '-92 dBm',
        'signalStatus': 'Satellite Link Stable',
        'narrative': 'Physical inspection of Substation Bravo reveals significant condensation near the primary cooling intake. Ultra-sonic scanning confirmed a microscopic hairline fracture in the joint assembly. Pressure remains within acceptable limits for now (428.5 kPa), but thermal variance suggests potential failure within 72 operating hours. Immediate technician dispatch is recommended for sealant application or joint replacement.',
        'unit': 'Mobile Field Unit 4',
      },
      {
        'id': 'FR-8830',
        'status': 'Submitted',
        'title': 'Line Node 412 Maintenance',
        'snippet': 'Routine capacitor replacement completed. Resistance levels within nominal range.',
        'investigator': 'Marcus Thorne',
        'time': '5 hours ago',
        'date': 'Oct 24, 2023',
        'time_exact': '11:15 PST',
        'image1': 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?q=80&w=600',
        'image2': 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?q=80&w=600',
        'reading': '112.4',
        'readingProgress': 0.4,
        'gps': '34.0622° N, 118.2537° W',
        'sector': 'Residential Zone A, Sector 2',
        'signal': '-84 dBm',
        'signalStatus': 'Strong Connection',
        'narrative': 'Line Node 412 maintenance was completed as scheduled. Capacitors C-12 and C-14 were replaced due to aging. Resistance testing showed values returned to nominal range (1.2 ohms). No further action required at this node for the current cycle.',
        'unit': 'Patrol Unit 7',
      },
      {
        'id': 'FR-8825',
        'status': 'Approved',
        'title': 'Sector 7 Perimeter Audit',
        'snippet': 'Full walk-through completed. All biometric sensors functioning at 98% efficiency.',
        'investigator': 'Eliza Vance',
        'time': 'Yesterday',
        'date': 'Oct 23, 2023',
        'time_exact': '09:45 PST',
        'image1': 'https://images.unsplash.com/photo-1557862921-37829c790f19?q=80&w=600',
        'image2': 'https://images.unsplash.com/photo-1579389083046-e3df9c2b3325?q=80&w=600',
        'reading': 'N/A',
        'readingProgress': 0.0,
        'gps': '34.0722° N, 118.2637° W',
        'sector': 'Perimeter Sector 7',
        'signal': '-78 dBm',
        'signalStatus': 'Line of Sight Stable',
        'narrative': 'Quarterly audit of Sector 7 perimeter systems completed. All biometric sensors were tested and verified at 98% detection efficiency. Perimeter lighting adjusted for optimal coverage. The southern gate hinge was lubricated. Full report approved by central security.',
        'unit': 'Base Hub Alpha',
      },
    ];
  }
}
