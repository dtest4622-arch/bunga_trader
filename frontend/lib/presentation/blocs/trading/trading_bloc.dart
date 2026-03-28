import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/trade_model.dart';
import '../../../data/models/signal_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/websocket_service.dart';
import 'package:hive/hive.dart';

part 'trading_event.dart';
part 'trading_state.dart';

class TradingBloc extends Bloc<TradingEvent, TradingState> {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();
  late Box<TradeModel> _tradesBox;
  late Box<SignalModel> _signalsBox;

  StreamSubscription? _tradeSubscription;
  StreamSubscription? _signalSubscription;

  TradingBloc() : super(TradingInitial()) {
    _initHive();
    _setupWebSocketListeners();

    on<LoadTrades>(_onLoadTrades);
    on<LoadSignals>(_onLoadSignals);
    on<ExecuteSignal>(_onExecuteSignal);
    on<RejectSignal>(_onRejectSignal);
    on<CloseTrade>(_onCloseTrade);
    on<ModifyTrade>(_onModifyTrade);
    on<CloseAllTrades>(_onCloseAllTrades);
    on<TradeUpdated>(_onTradeUpdated);
    on<SignalUpdated>(_onSignalUpdated);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _initHive() async {
    _tradesBox = Hive.box<TradeModel>('tradesBox');
    _signalsBox = Hive.box<SignalModel>('signalsBox');
  }

  void _setupWebSocketListeners() {
    _tradeSubscription = _webSocketService.tradeStream.listen((tradeData) {
      add(TradeUpdated(tradeData));
    });

    _signalSubscription = _webSocketService.signalStream.listen((signalData) {
      add(SignalUpdated(signalData));
    });
  }

  Future<void> _onLoadTrades(
      LoadTrades event, Emitter<TradingState> emit) async {
    emit(TradingLoading());

    try {
      // Load from local cache first
      final cachedTrades = _tradesBox.values.toList();
      if (cachedTrades.isNotEmpty) {
        emit(TradesLoaded(
          activeTrades: cachedTrades.where((t) => t.isOpen).toList(),
          tradeHistory: cachedTrades.where((t) => t.isClosed).toList(),
        ));
      }

      // Fetch from API
      final activeTradesData = await _apiService.getActiveTrades();
      final activeTrades =
          activeTradesData.map((t) => TradeModel.fromJson(t)).toList();

      final historyData = await _apiService.getTradeHistory();
      final history = historyData.map((t) => TradeModel.fromJson(t)).toList();

      // Update cache
      for (final trade in [...activeTrades, ...history]) {
        await _tradesBox.put(trade.id, trade);
      }

      emit(TradesLoaded(
        activeTrades: activeTrades,
        tradeHistory: history,
      ));
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadSignals(
      LoadSignals event, Emitter<TradingState> emit) async {
    emit(TradingLoading());

    try {
      // Load from local cache first
      final cachedSignals = _signalsBox.values.toList();
      if (cachedSignals.isNotEmpty) {
        emit(SignalsLoaded(signals: cachedSignals));
      }

      // Fetch from API
      final signalsData = await _apiService.getSignals();
      final signals = signalsData.map((s) => SignalModel.fromJson(s)).toList();

      // Update cache
      for (final signal in signals) {
        await _signalsBox.put(signal.id, signal);
      }

      emit(SignalsLoaded(signals: signals));
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onExecuteSignal(
      ExecuteSignal event, Emitter<TradingState> emit) async {
    try {
      emit(TradeExecuting());

      final response = await _apiService.executeSignal(
        event.signalId,
        event.accountId,
        autoExecute: event.autoExecute,
      );

      final trade = TradeModel.fromJson(response['trade']);
      await _tradesBox.put(trade.id, trade);

      // Update signal status
      final signal = _signalsBox.get(event.signalId);
      if (signal != null) {
        final updatedSignal = signal.copyWith(
          status: 'EXECUTED',
          tradeId: trade.id,
          executedAt: DateTime.now(),
        );
        await _signalsBox.put(event.signalId, updatedSignal);
      }

      emit(TradeExecuted(trade: trade));

      // Refresh trades
      add(LoadTrades());
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onRejectSignal(
      RejectSignal event, Emitter<TradingState> emit) async {
    try {
      await _apiService.rejectSignal(event.signalId, reason: event.reason);

      final signal = _signalsBox.get(event.signalId);
      if (signal != null) {
        final updatedSignal = signal.copyWith(
          status: 'REJECTED',
          rejectionReason: event.reason,
        );
        await _signalsBox.put(event.signalId, updatedSignal);
      }

      emit(SignalRejected(signalId: event.signalId));
      add(LoadSignals());
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCloseTrade(
      CloseTrade event, Emitter<TradingState> emit) async {
    try {
      emit(TradeClosing());

      final response = await _apiService.closeTrade(
        event.tradeId,
        partialPercent: event.partialPercent,
        reason: event.reason,
      );

      final trade = TradeModel.fromJson(response['trade']);
      await _tradesBox.put(trade.id, trade);

      emit(TradeClosed(trade: trade));
      add(LoadTrades());
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onModifyTrade(
      ModifyTrade event, Emitter<TradingState> emit) async {
    try {
      emit(TradeModifying());

      final response = await _apiService.modifyTrade(
        event.tradeId,
        newStopLoss: event.newStopLoss,
        newTakeProfit: event.newTakeProfit,
        newTakeProfit2: event.newTakeProfit2,
        newTakeProfit3: event.newTakeProfit3,
      );

      final trade = TradeModel.fromJson(response['trade']);
      await _tradesBox.put(trade.id, trade);

      emit(TradeModified(trade: trade));
      add(LoadTrades());
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCloseAllTrades(
      CloseAllTrades event, Emitter<TradingState> emit) async {
    try {
      emit(TradesClosing());

      await _apiService.closeAllTrades(pair: event.pair);

      emit(AllTradesClosed());
      add(LoadTrades());
    } catch (e) {
      emit(TradingError(message: _getErrorMessage(e)));
    }
  }

  void _onTradeUpdated(TradeUpdated event, Emitter<TradingState> emit) {
    final trade = TradeModel.fromJson(event.tradeData);
    _tradesBox.put(trade.id, trade);

    // Emit updated state if currently showing trades
    if (state is TradesLoaded) {
      final currentState = state as TradesLoaded;
      final updatedActiveTrades = currentState.activeTrades.map((t) {
        return t.id == trade.id ? trade : t;
      }).toList();

      emit(currentState.copyWith(activeTrades: updatedActiveTrades));
    }
  }

  void _onSignalUpdated(SignalUpdated event, Emitter<TradingState> emit) {
    final signal = SignalModel.fromJson(event.signalData);
    _signalsBox.put(signal.id, signal);

    // Emit updated state if currently showing signals
    if (state is SignalsLoaded) {
      final currentState = state as SignalsLoaded;
      final updatedSignals = currentState.signals.map((s) {
        return s.id == signal.id ? signal : s;
      }).toList();

      // Add new signal if not exists
      if (!updatedSignals.any((s) => s.id == signal.id)) {
        updatedSignals.insert(0, signal);
      }

      emit(currentState.copyWith(signals: updatedSignals));
    }
  }

  Future<void> _onRefreshData(
      RefreshData event, Emitter<TradingState> emit) async {
    add(LoadTrades());
    add(LoadSignals());
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('insufficient')) {
        return 'Insufficient balance for this trade';
      } else if (message.contains('margin')) {
        return 'Insufficient margin. Please check your account balance';
      } else if (message.contains('expired')) {
        return 'Signal has expired';
      } else if (message.contains('network')) {
        return 'Network error. Please check your connection';
      }
    }
    return 'Trading operation failed. Please try again';
  }

  @override
  Future<void> close() {
    _tradeSubscription?.cancel();
    _signalSubscription?.cancel();
    return super.close();
  }
}
