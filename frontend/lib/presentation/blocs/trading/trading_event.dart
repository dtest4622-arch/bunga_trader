part of 'trading_bloc.dart';

abstract class TradingEvent extends Equatable {
  const TradingEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrades extends TradingEvent {}

class LoadSignals extends TradingEvent {}

class ExecuteSignal extends TradingEvent {
  final String signalId;
  final String accountId;
  final bool autoExecute;

  const ExecuteSignal({
    required this.signalId,
    required this.accountId,
    this.autoExecute = false,
  });

  @override
  List<Object?> get props => [signalId, accountId, autoExecute];
}

class RejectSignal extends TradingEvent {
  final String signalId;
  final String? reason;

  const RejectSignal({
    required this.signalId,
    this.reason,
  });

  @override
  List<Object?> get props => [signalId, reason];
}

class CloseTrade extends TradingEvent {
  final String tradeId;
  final double? partialPercent;
  final String? reason;

  const CloseTrade({
    required this.tradeId,
    this.partialPercent,
    this.reason,
  });

  @override
  List<Object?> get props => [tradeId, partialPercent, reason];
}

class ModifyTrade extends TradingEvent {
  final String tradeId;
  final double? newStopLoss;
  final double? newTakeProfit;
  final double? newTakeProfit2;
  final double? newTakeProfit3;

  const ModifyTrade({
    required this.tradeId,
    this.newStopLoss,
    this.newTakeProfit,
    this.newTakeProfit2,
    this.newTakeProfit3,
  });

  @override
  List<Object?> get props => [tradeId, newStopLoss, newTakeProfit, newTakeProfit2, newTakeProfit3];
}

class CloseAllTrades extends TradingEvent {
  final String? pair;

  const CloseAllTrades({this.pair});

  @override
  List<Object?> get props => [pair];
}

class TradeUpdated extends TradingEvent {
  final Map<String, dynamic> tradeData;

  const TradeUpdated(this.tradeData);

  @override
  List<Object?> get props => [tradeData];
}

class SignalUpdated extends TradingEvent {
  final Map<String, dynamic> signalData;

  const SignalUpdated(this.signalData);

  @override
  List<Object?> get props => [signalData];
}

class RefreshData extends TradingEvent {}
