import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/backendless_data_service.dart';
import '../../../../features/meters/domain/meter.dart';
import '../../../../features/dashboard/domain/investigator.dart';

// ─── Pages ───────────────────────────────────────────────────────────────────

enum BackofficePage {
  dashboard,
  dataManagement,
  investigatorAssignments,
  fieldReports,
  notificationsChat,
  mapView,
  settings,
  billingDashboard,
}

final backofficePageProvider =
    StateProvider<BackofficePage>((ref) => BackofficePage.dashboard);

final isSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ─── Meters ───────────────────────────────────────────────────────────────────

final backofficeMetersProvider = FutureProvider<List<Meter>>((ref) async {
  final dataService = BackendlessDataService();
  final remoteMeters = await dataService.getRemoteMeters();
  
  // High-fidelity mock reports for the demo
  final mockReports = [
    Meter(
      id: 'MET-7829-X',
      customerName: 'Amina Okoro',
      address: '12 Crescent Way, Victoria Island',
      telephone: '+234 801 234 5678',
      tariffClass: 'Residential R2',
      gpsCoordinates: '6.4253° N, 3.4419° E',
      tariffActivity: TariffActivity.residential,
      geocode: 'VI-04',
      spnNumber: 'SPN-8821',
      brand: 'L&G',
      rating: '10(60)A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2022, 5, 15),
      findings: 'Meter bypass detected. Terminal seal broken and bridge wire discovered across internal shunt.',
      capturedImagePaths: [
        'https://images.unsplash.com/photo-1581092160562-40aa08e78837?q=80&w=600',
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=600'
      ],
    ),
    Meter(
      id: 'MET-4412-B',
      customerName: 'Chidi Azikiwe',
      address: 'Plot 45, Lekki Phase 1',
      telephone: '+234 802 345 6789',
      tariffClass: 'Commercial C1',
      gpsCoordinates: '6.4483° N, 3.4736° E',
      tariffActivity: TariffActivity.commercial,
      geocode: 'LK-02',
      spnNumber: 'SPN-9904',
      brand: 'EDMI',
      rating: '20(100)A',
      phase: MeterPhase.three,
      type: MeteringType.postpaid,
      status: MeterStatus.active,
      installationDate: DateTime(2021, 11, 20),
      findings: 'Suspicious tampering with optical port. Casing shows heat damage consistent with unauthorized access attempts.',
      capturedImagePaths: [
        'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=600'
      ],
      capturedVideoPath: 'mock_video_path.mp4',
    ),
    Meter(
      id: 'MET-9905-Z',
      customerName: 'Olu Jacobs',
      address: 'Avenue 7, Ikoyi',
      telephone: '+234 803 456 7890',
      tariffClass: 'Industrial I1',
      gpsCoordinates: '6.4550° N, 3.4350° E',
      tariffActivity: TariffActivity.industrial,
      geocode: 'IK-05',
      spnNumber: 'SPN-7712',
      brand: 'ABB',
      rating: '50(150)A',
      phase: MeterPhase.three,
      type: MeteringType.postpaid,
      status: MeterStatus.active,
      installationDate: DateTime(2023, 1, 10),
      findings: 'Magnetic interference detected. Traces of high-powered magnets found near the induction coil area.',
      capturedImagePaths: [],
    ),
    Meter(
      id: 'MET-1022-F',
      customerName: 'Sarah Boateng',
      address: '34 Osu Badu St, Dzorwulu',
      telephone: '+233 244 123 456',
      tariffClass: 'Residential R1',
      gpsCoordinates: '5.6171° N, 0.1947° W',
      tariffActivity: TariffActivity.residential,
      geocode: 'DZ-01',
      spnNumber: 'SPN-1022',
      brand: 'Itell',
      rating: '5(60)A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2020, 3, 12),
      findings: 'Tampered Meter: Evidence of physical breach on the enclosure seal.',
      capturedImagePaths: [],
    ),
    Meter(
      id: 'MET-5541-G',
      customerName: 'Kofi Mensah',
      address: 'Spintex Road, Accra',
      telephone: '+233 551 987 654',
      tariffClass: 'Commercial C2',
      gpsCoordinates: '5.6258° N, 0.1124° W',
      tariffActivity: TariffActivity.commercial,
      geocode: 'SP-05',
      spnNumber: 'SPN-5541',
      brand: 'Conlog',
      rating: '20(100)A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2021, 8, 22),
      findings: 'Relay Not Tripping: Remote disconnect command received but relay remained in closed state.',
      capturedImagePaths: [],
    ),
    Meter(
      id: 'MET-2022-H',
      customerName: 'Edward Mensah',
      address: 'Lartebiokorshie, Accra',
      telephone: '+233 201 111 222',
      tariffClass: 'Residential R1',
      gpsCoordinates: '5.5501° N, 0.2201° W',
      tariffActivity: TariffActivity.residential,
      geocode: 'LB-01',
      spnNumber: 'SPN-2022',
      brand: 'Itron',
      rating: '10(60)A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2022, 1, 15),
      findings: 'Communication Error: Signal strength at -110dBm. Concentrator unable to fetch daily consumption data.',
      capturedImagePaths: [],
    ),
    Meter(
      id: 'MET-3304-J',
      customerName: 'Joyce Appiah',
      address: 'Tema Community 5',
      telephone: '+233 544 333 444',
      tariffClass: 'Residential R2',
      gpsCoordinates: '5.6701° N, 0.0101° E',
      tariffActivity: TariffActivity.residential,
      geocode: 'TM-05',
      spnNumber: 'SPN-3304',
      brand: 'EDMI',
      rating: '15(60)A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2023, 6, 20),
      findings: 'Burnt Meter: Severe heat damage on the terminal cover and phase bridge.',
      capturedImagePaths: [],
    ),
    Meter(
      id: 'MET-9981-K',
      customerName: 'Daniel Osei',
      address: 'Kumasi, Adum',
      telephone: '+233 245 444 555',
      tariffClass: 'Commercial C1',
      gpsCoordinates: '6.6885° N, 1.6244° W',
      tariffActivity: TariffActivity.commercial,
      geocode: 'KS-02',
      spnNumber: 'SPN-9981',
      brand: 'L&G',
      rating: '20(100)A',
      phase: MeterPhase.three,
      type: MeteringType.postpaid,
      status: MeterStatus.faulty,
      installationDate: DateTime(2022, 12, 10),
      findings: 'Communication Error: PLC noise level too high for data packet delivery.',
      capturedImagePaths: [],
    ),
  ];

  return [...remoteMeters, ...mockReports];
});

final meterSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active filter: null = All, otherwise MeterStatus value
final meterStatusFilterProvider = StateProvider<MeterStatus?>((ref) => null);

final filteredMetersProvider = Provider<List<Meter>>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  final query = ref.watch(meterSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(meterStatusFilterProvider);

  return metersAsync.when(
    data: (meters) {
      var filtered = meters;
      if (query.isNotEmpty) {
        filtered = filtered
            .where((m) =>
                m.customerName.toLowerCase().contains(query) ||
                m.id.toLowerCase().contains(query) ||
                m.address.toLowerCase().contains(query))
            .toList();
      }
      if (statusFilter != null) {
        filtered = filtered.where((m) => m.status == statusFilter).toList();
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Findings ─────────────────────────────────────────────────────────────────

const findingCategories = [
  'All Faulty',
  'Tampered Meter',
  'Meter By-pass',
  'Already Disconnected',
  'Relay Not Tripping',
  'Communication Error',
  'Direct Connection',
  'Unauthorized Service conn.',
  'Unit Recovery',
  'Damage Meter',
  'Burnt Meter',
  'Others',
];

final faultyMetersCountProvider = Provider.family<int, String>((ref, category) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      final faultyMeters = meters.where((m) => m.status == MeterStatus.faulty).toList();
      
      int countFor(String cat) {
        return faultyMeters.where((m) {
          final findings = m.findings.toLowerCase();
          final c = cat.toLowerCase();
          if (c.contains('tamper') && findings.contains('tamper')) return true;
          if (c.contains('by-pass') && findings.contains('bypass')) return true;
          if (c.contains('disconnect') && findings.contains('disconnect')) return true;
          if (c.contains('relay') && findings.contains('relay')) return true;
          if (c.contains('communication') && findings.contains('communication')) return true;
          if (c.contains('direct') && findings.contains('direct')) return true;
          if (c.contains('unauthorized') && findings.contains('unauthorized')) return true;
          if (c.contains('recovery') && findings.contains('recovery')) return true;
          if (c.contains('damage') && (findings.contains('damage') || findings.contains('damaged'))) return true;
          if (c.contains('burnt') && (findings.contains('burnt') || findings.contains('burn'))) return true;
          return findings.contains(c);
        }).length;
      }

      if (category == 'All Faulty') {
        // The default "All Faulty" count should only comprise:
        // Relay Not Tripping, Communication Error, and Burnt Meter
        return countFor('Relay Not Tripping') + 
               countFor('Communication Error') + 
               countFor('Burnt Meter');
      }
      
      return countFor(category);
    },
    orElse: () => 0,
  );
});

// ─── Investigators ────────────────────────────────────────────────────────────

final backofficeInvestigatorsProvider =
    FutureProvider<List<Investigator>>((ref) async {
  final dataService = BackendlessDataService();
  return dataService.getInvestigators();
});

final selectedInvestigatorIdProvider = StateProvider<String?>((ref) => null);

/// Whether to show only available (online) investigators
final showOnlyAvailableProvider = StateProvider<bool>((ref) => false);

// ─── Field Reports ────────────────────────────────────────────────────────────

final selectedReportIndexProvider = StateProvider<int>((ref) => 0);

/// Map of reportId -> status overrides (local state for approve/reject)
final reportStatusOverridesProvider =
    StateProvider<Map<String, String>>((ref) => {});

// ─── Chat ─────────────────────────────────────────────────────────────────────

final selectedChatIndexProvider = StateProvider<int>((ref) => 0);

/// Map of conversationIndex -> list of chat message maps
final chatMessagesProvider = StateProvider<Map<int, List<Map<String, dynamic>>>>(
    (ref) => {});

/// Mark conversations as read when selected
final unreadConversationsProvider =
    StateProvider<Set<int>>((ref) => {0}); // 0 is unread by default
