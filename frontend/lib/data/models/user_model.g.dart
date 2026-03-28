// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      email: fields[1] as String,
      phoneNumber: fields[2] as String,
      mpesaNumber: fields[3] as String,
      isKycVerified: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      authToken: fields[6] as String?,
      refreshToken: fields[7] as String?,
      fullName: fields[8] as String?,
      avatarUrl: fields[9] as String?,
      isActive: fields[10] as bool,
      lastLogin: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.mpesaNumber)
      ..writeByte(4)
      ..write(obj.isKycVerified)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.authToken)
      ..writeByte(7)
      ..write(obj.refreshToken)
      ..writeByte(8)
      ..write(obj.fullName)
      ..writeByte(9)
      ..write(obj.avatarUrl)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.lastLogin);
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
