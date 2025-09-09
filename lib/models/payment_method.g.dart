// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentMethodModelAdapter extends TypeAdapter<PaymentMethodModel> {
  @override
  final int typeId = 8;

  @override
  PaymentMethodModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentMethodModel(
      id: fields[0] as String,
      name: fields[1] as String,
      iconName: fields[2] as String,
      iconColor: fields[3] as int,
      isDefault: fields[4] as bool,
      isBuiltIn: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentMethodModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconName)
      ..writeByte(3)
      ..write(obj.iconColor)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.isBuiltIn)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
