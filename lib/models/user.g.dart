// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 3;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      currency: fields[1] as String,
      googleAccountEmail: fields[2] as String?,
      googleAccountName: fields[3] as String?,
      isBackupEnabled: fields[4] as bool,
      lastBackupDate: fields[5] as DateTime?,
      lastSyncDate: fields[6] as DateTime?,
      notificationEnabled: fields[7] as bool,
      notificationTime: fields[8] as String?,
      biometricEnabled: fields[9] as bool,
      theme: fields[10] as String,
      language: fields[11] as String,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      monthlyBudgetLimit: fields[14] as double?,
      budgetAlertEnabled: fields[15] as bool,
      budgetAlertPercentage: fields[16] as int,
      pinCode: fields[17] as String?,
      pinEnabled: fields[18] as bool,
      isSetupCompleted: fields[19] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.currency)
      ..writeByte(2)
      ..write(obj.googleAccountEmail)
      ..writeByte(3)
      ..write(obj.googleAccountName)
      ..writeByte(4)
      ..write(obj.isBackupEnabled)
      ..writeByte(5)
      ..write(obj.lastBackupDate)
      ..writeByte(6)
      ..write(obj.lastSyncDate)
      ..writeByte(7)
      ..write(obj.notificationEnabled)
      ..writeByte(8)
      ..write(obj.notificationTime)
      ..writeByte(9)
      ..write(obj.biometricEnabled)
      ..writeByte(10)
      ..write(obj.theme)
      ..writeByte(11)
      ..write(obj.language)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.monthlyBudgetLimit)
      ..writeByte(15)
      ..write(obj.budgetAlertEnabled)
      ..writeByte(16)
      ..write(obj.budgetAlertPercentage)
      ..writeByte(17)
      ..write(obj.pinCode)
      ..writeByte(18)
      ..write(obj.pinEnabled)
      ..writeByte(19)
      ..write(obj.isSetupCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
