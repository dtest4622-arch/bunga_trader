part of 'account_bloc.dart';

abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccounts extends AccountEvent {}

class ConnectAccount extends AccountEvent {
  final String broker;
  final String login;
  final String password;
  final String server;
  final String platform;
  final String? accountType;

  const ConnectAccount({
    required this.broker,
    required this.login,
    required this.password,
    required this.server,
    this.platform = 'MT5',
    this.accountType,
  });

  @override
  List<Object?> get props => [broker, login, password, server, platform, accountType];
}

class DisconnectAccount extends AccountEvent {
  final String accountId;

  const DisconnectAccount({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

class SwitchAccount extends AccountEvent {
  final String accountId;

  const SwitchAccount({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

class SyncAccount extends AccountEvent {
  final String accountId;

  const SyncAccount({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

class BalanceUpdated extends AccountEvent {
  final Map<String, dynamic> balanceData;

  const BalanceUpdated(this.balanceData);

  @override
  List<Object?> get props => [balanceData];
}

class SetDefaultAccount extends AccountEvent {
  final String accountId;

  const SetDefaultAccount({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

class DepositRequested extends AccountEvent {
  final int amountKes;

  const DepositRequested({required this.amountKes});

  @override
  List<Object?> get props => [amountKes];
}

class WithdrawalRequested extends AccountEvent {
  final double amountUsd;
  final String? phoneNumber;

  const WithdrawalRequested({
    required this.amountUsd,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [amountUsd, phoneNumber];
}

class LoadTransactionHistory extends AccountEvent {
  final int limit;
  final int offset;

  const LoadTransactionHistory({
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [limit, offset];
}
