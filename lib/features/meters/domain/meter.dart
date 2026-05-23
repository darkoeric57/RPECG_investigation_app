import 'package:hive/hive.dart';
import '../../backoffice/domain/installment.dart';

part 'meter.g.dart';

@HiveType(typeId: 0)
enum MeterStatus { 
  @HiveField(0) paid, 
  @HiveField(1) pending, 
  @HiveField(2) billed,
  @HiveField(3) scheduled
}

@HiveType(typeId: 1)
enum TariffActivity { 
  @HiveField(0) residential, 
  @HiveField(1) commercial, 
  @HiveField(2) industrial 
}

@HiveType(typeId: 2)
enum MeterPhase { 
  @HiveField(0) single, 
  @HiveField(1) three 
}

@HiveType(typeId: 3)
enum MeteringType { 
  @HiveField(0) prepaid, 
  @HiveField(1) postpaid 
}

@HiveType(typeId: 4)
class Meter {
  @HiveField(0) final String id;
  @HiveField(1) final String customerName;
  @HiveField(2) final String address;
  @HiveField(3) final String telephone;
  @HiveField(4) final String tariffClass;
  @HiveField(5) final String gpsCoordinates;
  @HiveField(6) final TariffActivity tariffActivity;
  @HiveField(7) final String geocode;
  @HiveField(8) final String spnNumber;
  @HiveField(10) final String rating;
  @HiveField(11) final MeterPhase phase;
  @HiveField(12) final MeteringType type;
  @HiveField(13) final MeterStatus status;
  @HiveField(14) final DateTime installationDate;
  @HiveField(15) final bool isSynced;
  @HiveField(16) final String? findings;
  @HiveField(17) final String? initialReadings;
  @HiveField(18) final List<String> capturedImagePaths;
  @HiveField(19) final String? capturedVideoPath;
  @HiveField(20) final double? debtAmount;
  @HiveField(21) final String? offenseType;
  @HiveField(22) final DateTime? dateApprehended;
  @HiveField(23) final double? paidAmount;
  @HiveField(24) final String? objectId;
  @HiveField(25) final List<Installment>? installments;

  Meter({
    required this.id,
    required this.customerName,
    required this.address,
    required this.telephone,
    required this.tariffClass,
    required this.gpsCoordinates,
    required this.tariffActivity,
    required this.geocode,
    required this.spnNumber,
    required this.rating,
    required this.phase,
    required this.type,
    required this.status,
    required this.installationDate,
    this.isSynced = false,
    this.findings,
    this.initialReadings,
    this.capturedImagePaths = const [],
    this.capturedVideoPath,
    this.debtAmount,
    this.offenseType,
    this.dateApprehended,
    this.paidAmount,
    this.objectId,
    this.installments,
  });

  factory Meter.fromMap(Map<dynamic, dynamic> map) {
    // Helper for safe list conversion
    List<String> safeStringList(dynamic value) {
      if (value == null || value is! List) return [];
      return value.map((e) => e?.toString() ?? '').toList();
    }

    return Meter(
      id: (map['meterId'] ?? map['meterNumber'] ?? map['id'] ?? '').toString(),
      customerName: (map['customerName'] ?? 'Unknown').toString(),
      address: (map['address'] ?? 'No Address').toString(),
      telephone: (map['phoneNumber'] ?? map['telephone'] ?? '').toString(),
      tariffClass: (map['tariffClass'] ?? '').toString(),
      gpsCoordinates: (map['gpsCoordinates'] ?? '').toString(),
      tariffActivity: TariffActivity.values.firstWhere(
        (e) => e.name == (map['tariffActivity'] ?? 'residential').toString().toLowerCase(),
        orElse: () => TariffActivity.residential,
      ),
      geocode: (map['geocode'] ?? '').toString(),
      spnNumber: (map['spnNumber'] ?? '').toString(),
      rating: (map['meterRating'] ?? map['rating'] ?? '').toString(),
      phase: MeterPhase.values.firstWhere(
        (e) => e.name == (map['meterPhase'] ?? 'single').toString().toLowerCase(),
        orElse: () => MeterPhase.single,
      ),
      type: MeteringType.values.firstWhere(
        (e) => e.name == (map['meterType'] ?? 'prepaid').toString().toLowerCase(),
        orElse: () => MeteringType.prepaid,
      ),
      status: MeterStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending').toString().toLowerCase(),
        orElse: () => MeterStatus.pending,
      ),
      installationDate: map['installationDate'] != null 
          ? (map['installationDate'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['installationDate'] as int) 
              : DateTime.tryParse(map['installationDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isSynced: true,
      findings: map['findings']?.toString(),
      initialReadings: map['initialReadings']?.toString(),
      capturedImagePaths: safeStringList(map['imageUrls']),
      capturedVideoPath: map['videoUrl']?.toString(),
      debtAmount: map['debtAmount'] != null ? (map['debtAmount'] as num).toDouble() : null,
      offenseType: map['offenseType']?.toString(),
      dateApprehended: map['dateApprehended'] != null 
          ? (map['dateApprehended'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['dateApprehended'] as int) 
              : DateTime.tryParse(map['dateApprehended'].toString()))
          : null,
      paidAmount: map['paidAmount'] != null ? (map['paidAmount'] as num).toDouble() : null,
      objectId: map['objectId']?.toString(),
      installments: map['installments'] != null && map['installments'] is List
          ? (map['installments'] as List)
              .map((i) => Installment.fromMap(Map<String, dynamic>.from(i as Map)))
              .toList() 
          : null,
    );
  }

  Meter copyWith({
    MeterStatus? status,
    bool? isSynced,
    String? findings,
    double? debtAmount,
    double? paidAmount,
    List<Installment>? installments,
  }) {
    return Meter(
      id: id,
      customerName: customerName,
      address: address,
      telephone: telephone,
      tariffClass: tariffClass,
      gpsCoordinates: gpsCoordinates,
      tariffActivity: tariffActivity,
      geocode: geocode,
      spnNumber: spnNumber,
      rating: rating,
      phase: phase,
      type: type,
      status: status ?? this.status,
      installationDate: installationDate,
      isSynced: isSynced ?? this.isSynced,
      findings: findings ?? this.findings,
      initialReadings: initialReadings,
      capturedImagePaths: capturedImagePaths,
      capturedVideoPath: capturedVideoPath,
      debtAmount: debtAmount ?? this.debtAmount,
      offenseType: offenseType,
      dateApprehended: dateApprehended,
      paidAmount: paidAmount ?? this.paidAmount,
      objectId: objectId,
      installments: installments ?? this.installments,
    );
  }
}
