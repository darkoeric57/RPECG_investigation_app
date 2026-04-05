import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:files/features/backoffice/presentation/providers/backoffice_providers.dart';
import 'package:files/features/meters/domain/meter.dart';
import 'package:files/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MeterDetailsSummaryPage extends ConsumerWidget {
  const MeterDetailsSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meter = ref.watch(selectedMeterProvider);

    if (meter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('No meter record selected', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.dataManagement,
              child: const Text('Back to Archive'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 100),
        padding: const EdgeInsets.all(48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            _buildBreadcrumbs(ref),
            const SizedBox(height: 32),

            // Header: Customer Name & Contact
            _buildHeader(meter),
            const SizedBox(height: 64),

            // lifecycle/Stepper
            _buildLifecycleStatus(context, meter),
            const SizedBox(height: 48),

            // Primary info Grid
            _buildInfoGrid(meter),
            const SizedBox(height: 24),

            // Secondary info Grid
            _buildSecondaryGrid(meter),
            const SizedBox(height: 48),

            // Map/Evidence Section
            _buildEvidenceSection(meter),

            const SizedBox(height: 64),
            // Footer
            const Center(
              child: Text(
                'SOVEREIGN UTILITY INTELLIGENCE SYSTEM • CONFIDENTIAL FIELD LOG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFCBD5E1),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.dataManagement,
          child: const Text(
            'CASE ARCHIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 2.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        const Text(
          'SUMMARY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Meter meter) {
    return Center(
      child: Column(
        children: [
          Text(
            meter.customerName,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                meter.address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 24),
              const CircleAvatar(radius: 2, backgroundColor: Color(0xFFCBD5E1)),
              const SizedBox(width: 24),
              const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                meter.telephone,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStatus(BuildContext context, Meter meter) {
    int activeIndex = 0;
    if (meter.status == MeterStatus.pending) activeIndex = 0;
    else if (meter.status == MeterStatus.billed) activeIndex = 1;
    else if (meter.status == MeterStatus.scheduled) activeIndex = 2;
    else if (meter.status == MeterStatus.paid) activeIndex = 3;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CASE LIFECYCLE STATUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Current progression of the enforcement investigation',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF726200), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CURRENT PHASE: ${meter.status.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF726200)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: 20, left: 40, right: 40,
                    child: Container(
                      height: 2,
                      color: const Color(0xFFF1F5F9),
                    ),
                  ),
                  Positioned(
                    top: 20, left: 40,
                    width: (constraints.maxWidth - 80) * (activeIndex / 3),
                    child: Container(
                      height: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStep(1, 'Pending', 'Report missing', activeIndex >= 0),
                      _buildStep(2, 'Billed', 'Awaiting payment', activeIndex >= 1),
                      _buildStep(3, 'Scheduled', 'Installment plan', activeIndex >= 2),
                      _buildStep(4, 'Paid', 'Final settlement', activeIndex >= 3),
                    ],
                  ),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: isActive ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))] : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isActive ? AppTheme.primary : const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoGrid(Meter meter) {
    final currencyFormat = NumberFormat("#,##0.00", "en_US");
    return Row(
      children: [
        // Debt Card
        Expanded(
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL INDEBTEDNESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                const SizedBox(height: 24),
                Text(
                  'GH₵ ${currencyFormat.format(meter.debtAmount)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -1),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppTheme.error.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.error),
                      const SizedBox(width: 8),
                      const Text('OVERDUE INVESTIGATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Meter Spec
        Expanded(
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('METER IDENTIFIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      child: Text(meter.id, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSpecRow('SPN NUMBER', meter.spnNumber),
                const SizedBox(height: 8),
                _buildSpecRow('TARIFF PLAN', meter.tariffClass),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Enforcement
        Expanded(
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: const Border(bottom: BorderSide(color: AppTheme.error, width: 4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gavel_rounded, size: 40, color: AppTheme.error),
                const SizedBox(height: 16),
                const Text('OFFENSE CONFIRMED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  meter.offenseType.toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.error, letterSpacing: -0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Physical verification completed. Evidence archived.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildSecondaryGrid(Meter meter) {
    return Row(
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event_busy_rounded, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATE APPREHENDED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
                  Text(
                    meter.dateApprehended != null ? DateFormat('dd MMM yyyy').format(meter.dateApprehended!) : 'NOT RECORDED',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.explore_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SITE COORDINATES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
                    Text(
                      meter.gpsCoordinates,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map_rounded, size: 14),
                  label: const Text('VIEW ON GRID MAP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection(Meter meter) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ENFORCEMENT SITE MAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 2)),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: const Text('VIEW SATELLITE DETAILS'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 480,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBkR3Vy8hRLxaO6QR6SwsrqiaL3JGLtNI5ZrSxbKIhgX_ZWi3HBJ6RN31RLNF-PjzJXvN-KnmepRRo9RpgBDVyDpGCrot71__LPAvdgRIav79wRNn4VRIkQqc5PIKrZMZNQ1mdpkK0gNSDeZaPvTU1k8LdV-i6cYXcSGI_MQbj_KdoviaX9XFOZFtLoIZrzXN3GV-i0G3lv09iEh7iOBiZHjKjSU9zKL-6EYtL9HhDjW8BLkfXR3eGeOEN5FobZkt3GuK2dnMl1tH8'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(color: AppTheme.primary.withOpacity(0.05)),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _AnimatedPulse(color: AppTheme.error),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                            ),
                            child: const Icon(Icons.location_on_rounded, size: 32, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedPulse extends StatefulWidget {
  final Color color;
  const _AnimatedPulse({required this.color});

  @override
  State<_AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<_AnimatedPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
        return Container(
          width: 60 + (60 * _controller.value),
          height: 60 + (60 * _controller.value),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.3 * (1 - _controller.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
