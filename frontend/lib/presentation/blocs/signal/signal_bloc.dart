import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/signal_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/websocket_service.dart';
import 'package:hive/hive.dart';

part 'signal_event.dart';
part 'signal_state.dart';

class SignalBloc extends Bloc<SignalEvent, SignalState> {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();
  late Box<SignalModel> _signalsBox;
  
  StreamSubscription? _signalSubscription;

  SignalBloc() : super(SignalInitial()) {
    _initHive();
    _setupWebSocketListeners();
    
    on<LoadSignals>(_onLoadSignals);
    on<LoadSignalDetail>(_onLoadSignalDetail);
    on<FilterSignals>(_onFilterSignals);
    on<NewSignalReceived>(_onNewSignalReceived);
    on<MarkSignalAsRead>(_onMarkSignalAsRead);
    on<ClearSignalCache>(_onClearSignalCache);
  }

  Future<void> _initHive() async {
    _signalsBox = Hive.box<SignalModel>('signalsBox');
  }

  void _setupWebSocketListeners() {
    _signalSubscription = _webSocketService.signalStream.listen((signalData) {
      add(NewSignalReceived(signalData));
    });
  }

  Future<void> _onLoadSignals(LoadSignals event, Emitter<SignalState> emit) async {
    emit(SignalLoading());
    
    try {
      // Load from local cache first
      final cachedSignals = _signalsBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (cachedSignals.isNotEmpty) {
        emit(SignalsLoaded(
          signals: cachedSignals,
          unreadCount: cachedSignals.where((s) => s.isPending).length,
        ));
      }
      
      // Fetch from API
      final signalsData = await _apiService.getSignals(
        limit: event.limit,
        offset: event.offset,
        status: event.status,
        pair: event.pair,
      );
      
      final signals = signalsData.map((s) => SignalModel.fromJson(s)).toList();
      
      // Update cache
      for (final signal in signals) {
        await _signalsBox.put(signal.id, signal);
      }
      
      emit(SignalsLoaded(
        signals: signals,
        unreadCount: signals.where((s) => s.isPending).length,
      ));
    } catch (e) {
      emit(SignalError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadSignalDetail(LoadSignalDetail event, Emitter<SignalState> emit) async {
    try {
      // Check cache first
      final cachedSignal = _signalsBox.get(event.signalId);
      if (cachedSignal != null) {
        emit(SignalDetailLoaded(signal: cachedSignal));
      }
      
      // Fetch from API
      final signalData = await _apiService.getSignal(event.signalId);
      final signal = SignalModel.fromJson(signalData);
      
      await _signalsBox.put(signal.id, signal);
      
      emit(SignalDetailLoaded(signal: signal));
    } catch (e) {
      emit(SignalError(message: _getErrorMessage(e)));
    }
  }

  void _onFilterSignals(FilterSignals event, Emitter<SignalState> emit) {
    if (state is SignalsLoaded) {
      final currentState = state as SignalsLoaded;
      var filteredSignals = currentState.signals;
      
      if (event.pair != null && event.pair!.isNotEmpty) {
        filteredSignals = filteredSignals
            .where((s) => s.pair.toLowerCase().contains(event.pair!.toLowerCase()))
            .toList();
      }
      
      if (event.direction != null && event.direction!.isNotEmpty) {
        filteredSignals = filteredSignals
            .where((s) => s.direction == event.direction)
            .toList();
      }
      
      if (event.minConfidence != null) {
        filteredSignals = filteredSignals
            .where((s) => s.confidenceScore >= event.minConfidence!)
            .toList();
      }
      
      if (event.status != null && event.status!.isNotEmpty) {
        filteredSignals = filteredSignals
            .where((s) => s.status == event.status)
            .toList();
      }
      
      emit(currentState.copyWith(
        filteredSignals: filteredSignals,
        activeFilters: {
          if (event.pair != null) 'pair': event.pair,
          if (event.direction != null) 'direction': event.direction,
          if (event.minConfidence != null) 'minConfidence': event.minConfidence,
          if (event.status != null) 'status': event.status,
        },
      ));
    }
  }

  void _onNewSignalReceived(NewSignalReceived event, Emitter<SignalState> emit) {
    final signal = SignalModel.fromJson(event.signalData);
    _signalsBox.put(signal.id, signal);
    
    if (state is SignalsLoaded) {
      final currentState = state as SignalsLoaded;
      final updatedSignals = [signal, ...currentState.signals];
      
      emit(currentState.copyWith(
        signals: updatedSignals,
        unreadCount: updatedSignals.where((s) => s.isPending).length,
      ));
    } else {
      emit(SignalsLoaded(
        signals: [signal],
        unreadCount: signal.isPending ? 1 : 0,
      ));
    }
  }

  Future<void> _onMarkSignalAsRead(MarkSignalAsRead event, Emitter<SignalState> emit) async {
    // This would typically update a "read" status on the server
    // For now, we just update the local state
  }

  Future<void> _onClearSignalCache(ClearSignalCache event, Emitter<SignalState> emit) async {
    await _signalsBox.clear();
    emit(SignalCacheCleared());
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('network')) {
        return 'Network error. Please check your connection';
      }
    }
    return 'Failed to load signals. Please try again';
  }

  @override
  Future<void> close() {
    _signalSubscription?.cancel();
    return super.close();
  }
}
