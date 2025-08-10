// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncDataModelAdapter extends TypeAdapter<SyncDataModel> {
  @override
  final int typeId = 6;

  @override
  SyncDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncDataModel(
      id: fields[0] as String,
      dataType: fields[1] as String,
      dataId: fields[2] as String,
      action: fields[3] as String,
      timestamp: fields[4] as DateTime,
      synced: fields[5] as bool,
      errorMessage: fields[6] as String?,
      retryCount: fields[7] as int,
      dataSnapshot: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SyncDataModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dataType)
      ..writeByte(2)
      ..write(obj.dataId)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.synced)
      ..writeByte(6)
      ..write(obj.errorMessage)
      ..writeByte(7)
      ..write(obj.retryCount)
      ..writeByte(8)
      ..write(obj.dataSnapshot);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
