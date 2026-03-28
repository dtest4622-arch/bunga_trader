// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradingAccountModelAdapter extends TypeAdapter<TradingAccountModel> {
  @override
  final int typeId = 1;

  @override
  TradingAccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradingAccountModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      broker: fields[2] as String,
      accountType: fields[3] as String,
      platform: fields[4] as String,
      login: fields[5] as String,
      server: fields[6] as String,
      leverage: fields[7] as int,
      balance: fields[8] as double,
      equity: fields[9] as double,
      margin: fields[10] as double,
      freeMargin: fields[11] as double,
      marginLevel: fields[12] as double,
      isActive: fields[13] as bool,
      isDemo: fields[14] as bool,
      isDefault: fields[15] as bool,
      lastSynced: fields[16] as DateTime,
      createdAt: fields[17] as DateTime,
      accountCurrency: fields[18] as String?,
      openPositions: fields[19] as int,
      dailyPnl: fields[20] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TradingAccountModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.broker)
      ..writeByte(3)
      ..write(obj.accountType)
      ..writeByte(4)
      ..write(obj.platform)
      ..writeByte(5)
      ..write(obj.login)
      ..writeByte(6)
      ..write(obj.server)
      ..writeByte(7)
      ..write(obj.leverage)
      ..writeByte(8)
      ..write(obj.balance)
      ..writeByte(9)
      ..write(obj.equity)
      ..writeByte(10)
      ..write(obj.margin)
      ..writeByte(11)
      ..write(obj.freeMargin)
      ..writeByte(12)
      ..write(obj.marginLevel)
      ..writeByte(13)
      ..write(obj.isActive)
      ..writeByte(14)
      ..write(obj.isDemo)
      ..writeByte(15)
      ..write(obj.isDefault)
      ..writeByte(16)
      ..write(obj.lastSynced)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.accountCurrency)
      ..writeByte(19)
      ..write(obj.openPositions)
      ..writeByte(20)
      ..write(obj.dailyPnl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradingAccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
