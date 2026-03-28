part of 'signal_bloc.dart';

abstract class SignalEvent extends Equatable {
  const SignalEvent();

  @override
  List<Object?> get props => [];
}

class LoadSignals extends SignalEvent {
  final int limit;
  final int offset;
  final String? status;
  final String? pair;

  const LoadSignals({
    this.limit = 50,
    this.offset = 0,
    this.status,
    this.pair,
  });

  @override
  List<Object?> get props => [limit, offset, status, pair];
}

class LoadSignalDetail extends SignalEvent {
  final String signalId;

  const LoadSignalDetail({required this.signalId});

  @override
  List<Object?> get props => [signalId];
}

class FilterSignals extends SignalEvent {
  final String? pair;
  final String? direction;
  final int? minConfidence;
  final String? status;

  const FilterSignals({
    this.pair,
    this.direction,
    this.minConfidence,
    this.status,
  });

  @override
  List<Object?> get props => [pair, direction, minConfidence, status];
}

class NewSignalReceived extends SignalEvent {
  final Map<String, dynamic> signalData;

  const NewSignalReceived(this.signalData);

  @override
  List<Object?> get props => [signalData];
}

class MarkSignalAsRead extends SignalEvent {
  final String signalId;

  const MarkSignalAsRead({required this.signalId});

  @override
  List<Object?> get props => [signalId];
}

class ClearSignalCache extends SignalEvent {}
