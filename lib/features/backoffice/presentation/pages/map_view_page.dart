import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/dashboard/domain/investigator.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> with SingleTickerProviderStateMixin {
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
    final investigatorsAsync = ref.watch(backofficeInvestigatorsProvider);

    return Stack(
      children: [
        // Dark background for the radar
        Container(color: const Color(0xFF0F172A)),
        // Background Grid & Radar
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: RadarPainter(_controller.value),
              );
            },
          ),
        ),
        
        // Floating Info Overlays
        Positioned(
          top: 32,
          left: 32,
          child: _buildMapHeader(),
        ),
        
        Positioned(
          top: 32,
          right: 32,
          child: _buildLegend(),
        ),

        // Investigator Markers
        investigatorsAsync.when(
          data: (investigators) {
            final list = investigators.isEmpty ? _getMockInvestigators() : investigators;
            return Stack(
              children: list.asMap().entries.map((entry) {
                final i = entry.value;
                final idx = entry.key;
                final angle = (idx * 2 * math.pi / list.length) + (idx * 0.5);
                final distance = 100.0 + (idx * 40.0);
                
                return _RadarMarker(
                  investigator: i,
                  angle: angle,
                  distance: distance,
                  controller: _controller,
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),

        // Bottom Control Panel
        Positioned(
          bottom: 32,
          left: 32,
          right: 32,
          child: _buildControlPanel(),
        ),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Tracking Radar',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '8 Field Agents Online (Active Protocol: RPECG-04)',
              style: TextStyle(color: AppTheme.textLight, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem('Active Agent', AppTheme.primary),
          const SizedBox(height: 8),
          _buildLegendItem('Offline Agent', Colors.grey),
          const SizedBox(height: 8),
          _buildLegendItem('Alert / Issue', AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(Icons.my_location, 'Recenter'),
        const SizedBox(width: 16),
        _buildActionButton(Icons.layers, 'Satellite View'),
        const SizedBox(width: 16),
        _buildActionButton(Icons.filter_list, 'Filter Regions'),
        const SizedBox(width: 16),
        _buildActionButton(Icons.security, 'Toggle Geo-Fencing'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Investigator> _getMockInvestigators() {
    return [
      Investigator(id: '1', name: 'John Doe', location: 'Lagos', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '2', name: 'Sarah Smith', location: 'Ikeja', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '3', name: 'Mike Ross', location: 'VI', imageUrl: '', status: InvestigatorStatus.offline),
      Investigator(id: '4', name: 'Jessica P.', location: 'Lekki', imageUrl: '', status: InvestigatorStatus.online),
      Investigator(id: '5', name: 'Harvey S.', location: 'Surulere', imageUrl: '', status: InvestigatorStatus.online),
    ];
  }
}

class RadarPainter extends CustomPainter {
  final double progress;
  RadarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Background Grid lines
    paint.color = Colors.white.withValues(alpha: 0.03);
    for (var i = 1; i <= 6; i++) {
      canvas.drawCircle(center, i * 60.0, paint);
    }

    // Crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paint);

    // Diagonal lines
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    final sweepShader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          AppTheme.primary.withValues(alpha: 0.0),
          AppTheme.primary.withValues(alpha: 0.2),
          AppTheme.primary.withValues(alpha: 0.0),
        ],
        stops: [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 4));

    canvas.drawCircle(center, size.width / 4, Paint()..shader = sweepShader..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => oldDelegate.progress != progress;
}

class _RadarMarker extends StatelessWidget {
  final Investigator investigator;
  final double angle;
  final double distance;
  final Animation<double> controller;

  const _RadarMarker({
    required this.investigator,
    required this.angle,
    required this.distance,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final x = center.dx + distance * math.cos(angle);
        final y = center.dy + distance * math.sin(angle);

        return Positioned(
          left: x - 20,
          top: y - 20,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final ping = (controller.value * 2) % 1.0;
              final isOnline = investigator.status == InvestigatorStatus.online;
              final color = isOnline ? AppTheme.primary : Colors.grey;

              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse effect
                      if (isOnline)
                        Container(
                          width: 40 * ping,
                          height: 40 * ping,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withValues(alpha: 1.0 - ping), width: 2),
                          ),
                        ),
                      // Marker Point
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      investigator.name,
                      style: const TextStyle(fontSize: 9, color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
