// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeterAdapter extends TypeAdapter<Meter> {
  @override
  final int typeId = 4;

  @override
  Meter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meter(
      id: fields[0] as String,
      customerName: fields[1] as String,
      address: fields[2] as String,
      telephone: fields[3] as String,
      tariffClass: fields[4] as String,
      gpsCoordinates: fields[5] as String,
      tariffActivity: fields[6] as TariffActivity,
      geocode: fields[7] as String,
      spnNumber: fields[8] as String,
      brand: fields[9] as String,
      rating: fields[10] as String,
      phase: fields[11] as MeterPhase,
      type: fields[12] as MeteringType,
      status: fields[13] as MeterStatus,
      installationDate: fields[14] as DateTime,
      isSynced: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Meter obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.telephone)
      ..writeByte(4)
      ..write(obj.tariffClass)
      ..writeByte(5)
      ..write(obj.gpsCoordinates)
      ..writeByte(6)
      ..write(obj.tariffActivity)
      ..writeByte(7)
      ..write(obj.geocode)
      ..writeByte(8)
      ..write(obj.spnNumber)
      ..writeByte(9)
      ..write(obj.brand)
      ..writeByte(10)
      ..write(obj.rating)
      ..writeByte(11)
      ..write(obj.phase)
      ..writeByte(12)
      ..write(obj.type)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.installationDate)
      ..writeByte(15)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeterStatusAdapter extends TypeAdapter<MeterStatus> {
  @override
  final int typeId = 0;

  @override
  MeterStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeterStatus.active;
      case 1:
        return MeterStatus.pending;
      case 2:
        return MeterStatus.faulty;
      default:
        return MeterStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, MeterStatus obj) {
    switch (obj) {
      case MeterStatus.active:
        writer.writeByte(0);
        break;
      case MeterStatus.pending:
        writer.writeByte(1);
        break;
      case MeterStatus.faulty:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TariffActivityAdapter extends TypeAdapter<TariffActivity> {
  @override
  final int typeId = 1;

  @override
  TariffActivity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TariffActivity.residential;
      case 1:
        return TariffActivity.commercial;
      case 2:
        return TariffActivity.industrial;
      default:
        return TariffActivity.residential;
    }
  }

  @override
  void write(BinaryWriter writer, TariffActivity obj) {
    switch (obj) {
      case TariffActivity.residential:
        writer.writeByte(0);
        break;
      case TariffActivity.commercial:
        writer.writeByte(1);
        break;
      case TariffActivity.industrial:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TariffActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeterPhaseAdapter extends TypeAdapter<MeterPhase> {
  @override
  final int typeId = 2;

  @override
  MeterPhase read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeterPhase.single;
      case 1:
        return MeterPhase.three;
      default:
        return MeterPhase.single;
    }
  }

  @override
  void write(BinaryWriter writer, MeterPhase obj) {
    switch (obj) {
      case MeterPhase.single:
        writer.writeByte(0);
        break;
      case MeterPhase.three:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterPhaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeteringTypeAdapter extends TypeAdapter<MeteringType> {
  @override
  final int typeId = 3;

  @override
  MeteringType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeteringType.prepaid;
      case 1:
        return MeteringType.postpaid;
      default:
        return MeteringType.prepaid;
    }
  }

  @override
  void write(BinaryWriter writer, MeteringType obj) {
    switch (obj) {
      case MeteringType.prepaid:
        writer.writeByte(0);
        break;
      case MeteringType.postpaid:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeteringTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
