part of 'account_bloc.dart';

abstract class AccountState extends Equatable {
  const AccountState();

  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountsLoaded extends AccountState {
  final List<TradingAccountModel> accounts;
  final TradingAccountModel? selectedAccount;

  const AccountsLoaded({
    required this.accounts,
    this.selectedAccount,
  });

  AccountsLoaded copyWith({
    List<TradingAccountModel>? accounts,
    TradingAccountModel? selectedAccount,
  }) {
    return AccountsLoaded(
      accounts: accounts ?? this.accounts,
      selectedAccount: selectedAccount ?? this.selectedAccount,
    );
  }

  @override
  List<Object?> get props => [accounts, selectedAccount];
}

class AccountConnected extends AccountState {
  final TradingAccountModel account;

  const AccountConnected({required this.account});

  @override
  List<Object?> get props => [account];
}

class AccountDisconnected extends AccountState {
  final String accountId;

  const AccountDisconnected({required this.accountId});

  @override
  List<Object?> get props => [accountId];
}

class AccountSwitched extends AccountState {
  final TradingAccountModel account;

  const AccountSwitched({required this.account});

  @override
  List<Object?> get props => [account];
}

class AccountSynced extends AccountState {
  final TradingAccountModel account;

  const AccountSynced({required this.account});

  @override
  List<Object?> get props => [account];
}

class DepositProcessing extends AccountState {}

class DepositInitiated extends AccountState {
  final String checkoutRequestId;
  final int amount;

  const DepositInitiated({
    required this.checkoutRequestId,
    required this.amount,
  });

  @override
  List<Object?> get props => [checkoutRequestId, amount];
}

class WithdrawalProcessing extends AccountState {}

class WithdrawalRequestedState extends AccountState {
  final String requestId;
  final double amount;

  const WithdrawalRequestedState({
    required this.requestId,
    required this.amount,
  });

  @override
  List<Object?> get props => [requestId, amount];
}

class TransactionHistoryLoaded extends AccountState {
  final List<Map<String, dynamic>> transactions;

  const TransactionHistoryLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}

class AccountError extends AccountState {
  final String message;

  const AccountError({required this.message});

  @override
  List<Object?> get props => [message];
}
