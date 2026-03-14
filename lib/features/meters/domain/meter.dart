import 'package:hive/hive.dart';

part 'meter.g.dart';

@HiveType(typeId: 0)
enum MeterStatus { 
  @HiveField(0) active, 
  @HiveField(1) pending, 
  @HiveField(2) faulty 
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
  @HiveField(9) final String brand;
  @HiveField(10) final String rating;
  @HiveField(11) final MeterPhase phase;
  @HiveField(12) final MeteringType type;
  @HiveField(13) final MeterStatus status;
  @HiveField(14) final DateTime installationDate;
  @HiveField(15) final bool isSynced;

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
    required this.brand,
    required this.rating,
    required this.phase,
    required this.type,
    required this.status,
    required this.installationDate,
    this.isSynced = false,
  });

  Meter copyWith({
    String? id,
    String? customerName,
    String? address,
    String? telephone,
    String? tariffClass,
    String? gpsCoordinates,
    TariffActivity? tariffActivity,
    String? geocode,
    String? spnNumber,
    String? brand,
    String? rating,
    MeterPhase? phase,
    MeteringType? type,
    MeterStatus? status,
    DateTime? installationDate,
    bool? isSynced,
  }) {
    return Meter(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      telephone: telephone ?? this.telephone,
      tariffClass: tariffClass ?? this.tariffClass,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      tariffActivity: tariffActivity ?? this.tariffActivity,
      geocode: geocode ?? this.geocode,
      spnNumber: spnNumber ?? this.spnNumber,
      brand: brand ?? this.brand,
      rating: rating ?? this.rating,
      phase: phase ?? this.phase,
      type: type ?? this.type,
      status: status ?? this.status,
      installationDate: installationDate ?? this.installationDate,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
