// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investigator.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvestigatorAdapter extends TypeAdapter<Investigator> {
  @override
  final int typeId = 6;

  @override
  Investigator read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Investigator(
      id: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as String,
      imageUrl: fields[3] as String,
      status: fields[4] as InvestigatorStatus,
    );
  }

  @override
  void write(BinaryWriter writer, Investigator obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestigatorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvestigatorStatusAdapter extends TypeAdapter<InvestigatorStatus> {
  @override
  final int typeId = 5;

  @override
  InvestigatorStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvestigatorStatus.online;
      case 1:
        return InvestigatorStatus.offline;
      default:
        return InvestigatorStatus.online;
    }
  }

  @override
  void write(BinaryWriter writer, InvestigatorStatus obj) {
    switch (obj) {
      case InvestigatorStatus.online:
        writer.writeByte(0);
        break;
      case InvestigatorStatus.offline:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvestigatorStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
