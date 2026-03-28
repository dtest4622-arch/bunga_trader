// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignalModelAdapter extends TypeAdapter<SignalModel> {
  @override
  final int typeId = 2;

  @override
  SignalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SignalModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      groupName: fields[2] as String,
      rawMessage: fields[3] as String,
      pair: fields[4] as String,
      direction: fields[5] as String,
      entryPrice: fields[6] as double?,
      stopLoss: fields[7] as double?,
      takeProfit: fields[8] as double?,
      takeProfit2: fields[9] as double?,
      takeProfit3: fields[10] as double?,
      aiLotSize: fields[11] as double,
      aiStopLoss: fields[12] as double,
      aiTakeProfit: fields[13] as double,
      riskPercent: fields[14] as double,
      confidenceScore: fields[15] as int,
      status: fields[16] as String,
      createdAt: fields[17] as DateTime,
      executedAt: fields[18] as DateTime?,
      expiredAt: fields[19] as DateTime?,
      tradeId: fields[20] as String?,
      rejectionReason: fields[21] as String?,
      rrRatio: fields[22] as double?,
      timeFrame: fields[23] as String?,
      analysis: fields[24] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SignalModel obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.groupName)
      ..writeByte(3)
      ..write(obj.rawMessage)
      ..writeByte(4)
      ..write(obj.pair)
      ..writeByte(5)
      ..write(obj.direction)
      ..writeByte(6)
      ..write(obj.entryPrice)
      ..writeByte(7)
      ..write(obj.stopLoss)
      ..writeByte(8)
      ..write(obj.takeProfit)
      ..writeByte(9)
      ..write(obj.takeProfit2)
      ..writeByte(10)
      ..write(obj.takeProfit3)
      ..writeByte(11)
      ..write(obj.aiLotSize)
      ..writeByte(12)
      ..write(obj.aiStopLoss)
      ..writeByte(13)
      ..write(obj.aiTakeProfit)
      ..writeByte(14)
      ..write(obj.riskPercent)
      ..writeByte(15)
      ..write(obj.confidenceScore)
      ..writeByte(16)
      ..write(obj.status)
      ..writeByte(17)
      ..write(obj.createdAt)
      ..writeByte(18)
      ..write(obj.executedAt)
      ..writeByte(19)
      ..write(obj.expiredAt)
      ..writeByte(20)
      ..write(obj.tradeId)
      ..writeByte(21)
      ..write(obj.rejectionReason)
      ..writeByte(22)
      ..write(obj.rrRatio)
      ..writeByte(23)
      ..write(obj.timeFrame)
      ..writeByte(24)
      ..write(obj.analysis);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
