part of 'signal_bloc.dart';

abstract class SignalState extends Equatable {
  const SignalState();

  @override
  List<Object?> get props => [];
}

class SignalInitial extends SignalState {}

class SignalLoading extends SignalState {}

class SignalsLoaded extends SignalState {
  final List<SignalModel> signals;
  final List<SignalModel>? filteredSignals;
  final int unreadCount;
  final Map<String, dynamic>? activeFilters;

  const SignalsLoaded({
    required this.signals,
    this.filteredSignals,
    this.unreadCount = 0,
    this.activeFilters,
  });

  SignalsLoaded copyWith({
    List<SignalModel>? signals,
    List<SignalModel>? filteredSignals,
    int? unreadCount,
    Map<String, dynamic>? activeFilters,
  }) {
    return SignalsLoaded(
      signals: signals ?? this.signals,
      filteredSignals: filteredSignals ?? this.filteredSignals,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }

  List<SignalModel> get displaySignals => filteredSignals ?? signals;

  @override
  List<Object?> get props => [signals, filteredSignals, unreadCount, activeFilters];
}

class SignalDetailLoaded extends SignalState {
  final SignalModel signal;

  const SignalDetailLoaded({required this.signal});

  @override
  List<Object?> get props => [signal];
}

class SignalCacheCleared extends SignalState {}

class SignalError extends SignalState {
  final String message;

  const SignalError({required this.message});

  @override
  List<Object?> get props => [message];
}
