// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeModelAdapter extends TypeAdapter<TradeModel> {
  @override
  final int typeId = 3;

  @override
  TradeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeModel(
      id: fields[0] as String,
      signalId: fields[1] as String,
      accountId: fields[2] as String,
      brokerTicket: fields[3] as int,
      pair: fields[4] as String,
      direction: fields[5] as String,
      entryPrice: fields[6] as double,
      lotSize: fields[7] as double,
      stopLoss: fields[8] as double,
      takeProfit: fields[9] as double,
      currentPrice: fields[10] as double?,
      floatingPnl: fields[11] as double?,
      status: fields[12] as String,
      openedAt: fields[13] as DateTime,
      closedAt: fields[14] as DateTime?,
      closedPrice: fields[15] as double?,
      finalPnl: fields[16] as double?,
      closeReason: fields[17] as String?,
      partialCloses: (fields[18] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, dynamic>())
          ?.toList(),
      commission: fields[19] as double?,
      swap: fields[20] as double?,
      comment: fields[21] as String?,
      takeProfit2: fields[22] as double?,
      takeProfit3: fields[23] as double?,
      originalStopLoss: fields[24] as double?,
      originalTakeProfit: fields[25] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, TradeModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.signalId)
      ..writeByte(2)
      ..write(obj.accountId)
      ..writeByte(3)
      ..write(obj.brokerTicket)
      ..writeByte(4)
      ..write(obj.pair)
      ..writeByte(5)
      ..write(obj.direction)
      ..writeByte(6)
      ..write(obj.entryPrice)
      ..writeByte(7)
      ..write(obj.lotSize)
      ..writeByte(8)
      ..write(obj.stopLoss)
      ..writeByte(9)
      ..write(obj.takeProfit)
      ..writeByte(10)
      ..write(obj.currentPrice)
      ..writeByte(11)
      ..write(obj.floatingPnl)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.openedAt)
      ..writeByte(14)
      ..write(obj.closedAt)
      ..writeByte(15)
      ..write(obj.closedPrice)
      ..writeByte(16)
      ..write(obj.finalPnl)
      ..writeByte(17)
      ..write(obj.closeReason)
      ..writeByte(18)
      ..write(obj.partialCloses)
      ..writeByte(19)
      ..write(obj.commission)
      ..writeByte(20)
      ..write(obj.swap)
      ..writeByte(21)
      ..write(obj.comment)
      ..writeByte(22)
      ..write(obj.takeProfit2)
      ..writeByte(23)
      ..write(obj.takeProfit3)
      ..writeByte(24)
      ..write(obj.originalStopLoss)
      ..writeByte(25)
      ..write(obj.originalTakeProfit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
