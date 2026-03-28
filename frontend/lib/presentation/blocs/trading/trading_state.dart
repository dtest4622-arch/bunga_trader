part of 'trading_bloc.dart';

abstract class TradingState extends Equatable {
  const TradingState();

  @override
  List<Object?> get props => [];
}

class TradingInitial extends TradingState {}

class TradingLoading extends TradingState {}

class TradesLoaded extends TradingState {
  final List<TradeModel> activeTrades;
  final List<TradeModel> tradeHistory;

  const TradesLoaded({
    required this.activeTrades,
    required this.tradeHistory,
  });

  TradesLoaded copyWith({
    List<TradeModel>? activeTrades,
    List<TradeModel>? tradeHistory,
  }) {
    return TradesLoaded(
      activeTrades: activeTrades ?? this.activeTrades,
      tradeHistory: tradeHistory ?? this.tradeHistory,
    );
  }

  @override
  List<Object?> get props => [activeTrades, tradeHistory];
}

class SignalsLoaded extends TradingState {
  final List<SignalModel> signals;

  const SignalsLoaded({required this.signals});

  SignalsLoaded copyWith({
    List<SignalModel>? signals,
  }) {
    return SignalsLoaded(
      signals: signals ?? this.signals,
    );
  }

  @override
  List<Object?> get props => [signals];
}

class TradeExecuting extends TradingState {}

class TradeExecuted extends TradingState {
  final TradeModel trade;

  const TradeExecuted({required this.trade});

  @override
  List<Object?> get props => [trade];
}

class SignalRejected extends TradingState {
  final String signalId;

  const SignalRejected({required this.signalId});

  @override
  List<Object?> get props => [signalId];
}

class TradeClosing extends TradingState {}

class TradeClosed extends TradingState {
  final TradeModel trade;

  const TradeClosed({required this.trade});

  @override
  List<Object?> get props => [trade];
}

class TradeModifying extends TradingState {}

class TradeModified extends TradingState {
  final TradeModel trade;

  const TradeModified({required this.trade});

  @override
  List<Object?> get props => [trade];
}

class TradesClosing extends TradingState {}

class AllTradesClosed extends TradingState {}

class TradingError extends TradingState {
  final String message;

  const TradingError({required this.message});

  @override
  List<Object?> get props => [message];
}
