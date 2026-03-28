import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/trading_account_model.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/websocket_service.dart';
import 'package:hive/hive.dart';

part 'account_event.dart';
part 'account_state.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final ApiService _apiService = ApiService();
  final WebSocketService _webSocketService = WebSocketService();
  late Box<TradingAccountModel> _accountsBox;

  StreamSubscription? _balanceSubscription;
  Timer? _syncTimer;

  AccountBloc() : super(AccountInitial()) {
    _initHive();
    _setupWebSocketListeners();

    on<LoadAccounts>(_onLoadAccounts);
    on<ConnectAccount>(_onConnectAccount);
    on<DisconnectAccount>(_onDisconnectAccount);
    on<SwitchAccount>(_onSwitchAccount);
    on<SyncAccount>(_onSyncAccount);
    on<BalanceUpdated>(_onBalanceUpdated);
    on<SetDefaultAccount>(_onSetDefaultAccount);
    on<DepositRequested>(_onDepositRequested);
    on<WithdrawalRequested>(_onWithdrawalRequested);
    on<LoadTransactionHistory>(_onLoadTransactionHistory);
  }

  Future<void> _initHive() async {
    _accountsBox = Hive.box<TradingAccountModel>('accountsBox');
  }

  void _setupWebSocketListeners() {
    _balanceSubscription =
        _webSocketService.balanceStream.listen((balanceData) {
      add(BalanceUpdated(balanceData));
    });
  }

  Future<void> _onLoadAccounts(
      LoadAccounts event, Emitter<AccountState> emit) async {
    emit(AccountLoading());

    try {
      // Load from local cache first
      final cachedAccounts = _accountsBox.values.toList();
      if (cachedAccounts.isNotEmpty) {
        final defaultAccount = cachedAccounts.firstWhere(
          (a) => a.isDefault,
          orElse: () => cachedAccounts.first,
        );
        emit(AccountsLoaded(
          accounts: cachedAccounts,
          selectedAccount: defaultAccount,
        ));
      }

      // Fetch from API
      final accountsData = await _apiService.getTradingAccounts();
      final accounts =
          accountsData.map((a) => TradingAccountModel.fromJson(a)).toList();

      // Update cache
      for (final account in accounts) {
        await _accountsBox.put(account.id, account);
      }

      final selectedAccount = accounts.isNotEmpty
          ? accounts.firstWhere(
              (a) => a.isDefault,
              orElse: () => accounts.first,
            )
          : null;

      emit(AccountsLoaded(
        accounts: accounts,
        selectedAccount: selectedAccount,
      ));

      // Subscribe to WebSocket updates for selected account
      if (selectedAccount != null) {
        _webSocketService.subscribeToAccount(selectedAccount.id);
      }
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onConnectAccount(
      ConnectAccount event, Emitter<AccountState> emit) async {
    emit(AccountLoading());

    try {
      final response = await _apiService.connectBrokerAccount(
        event.broker,
        event.login,
        event.password,
        event.server,
        platform: event.platform,
        accountType: event.accountType,
      );

      final account = TradingAccountModel.fromJson(response);
      await _accountsBox.put(account.id, account);

      emit(AccountConnected(account: account));
      add(LoadAccounts());
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onDisconnectAccount(
      DisconnectAccount event, Emitter<AccountState> emit) async {
    try {
      await _apiService.disconnectBrokerAccount(event.accountId);
      await _accountsBox.delete(event.accountId);

      emit(AccountDisconnected(accountId: event.accountId));
      add(LoadAccounts());
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSwitchAccount(
      SwitchAccount event, Emitter<AccountState> emit) async {
    try {
      await _apiService.switchActiveAccount(event.accountId);

      final account = _accountsBox.get(event.accountId);
      if (account != null) {
        // Unsubscribe from old account
        _webSocketService.unsubscribeFromAccount(event.accountId);

        // Subscribe to new account
        _webSocketService.subscribeToAccount(event.accountId);

        emit(AccountSwitched(account: account));

        // Update current state
        if (state is AccountsLoaded) {
          final currentState = state as AccountsLoaded;
          emit(currentState.copyWith(selectedAccount: account));
        }
      }
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onSyncAccount(
      SyncAccount event, Emitter<AccountState> emit) async {
    try {
      final response = await _apiService.syncAccount(event.accountId);
      final account = TradingAccountModel.fromJson(response);
      await _accountsBox.put(account.id, account);

      if (state is AccountsLoaded) {
        final currentState = state as AccountsLoaded;
        final updatedAccounts = currentState.accounts.map((a) {
          return a.id == account.id ? account : a;
        }).toList();

        emit(currentState.copyWith(
          accounts: updatedAccounts,
          selectedAccount: currentState.selectedAccount?.id == account.id
              ? account
              : currentState.selectedAccount,
        ));
      }

      emit(AccountSynced(account: account));
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  void _onBalanceUpdated(BalanceUpdated event, Emitter<AccountState> emit) {
    if (state is AccountsLoaded) {
      final currentState = state as AccountsLoaded;
      final accountId = event.balanceData['account_id'];

      final updatedAccounts = currentState.accounts.map((account) {
        if (account.id == accountId) {
          return account.copyWith(
            balance:
                event.balanceData['balance']?.toDouble() ?? account.balance,
            equity: event.balanceData['equity']?.toDouble() ?? account.equity,
            margin: event.balanceData['margin']?.toDouble() ?? account.margin,
            freeMargin: event.balanceData['free_margin']?.toDouble() ??
                account.freeMargin,
            marginLevel: event.balanceData['margin_level']?.toDouble() ??
                account.marginLevel,
            openPositions:
                event.balanceData['open_positions'] ?? account.openPositions,
            dailyPnl:
                event.balanceData['daily_pnl']?.toDouble() ?? account.dailyPnl,
            lastSynced: DateTime.now(),
          );
        }
        return account;
      }).toList();

      final updatedSelected = currentState.selectedAccount?.id == accountId
          ? updatedAccounts.firstWhere((a) => a.id == accountId)
          : currentState.selectedAccount;

      emit(currentState.copyWith(
        accounts: updatedAccounts,
        selectedAccount: updatedSelected,
      ));

      // Update cache
      if (updatedSelected != null) {
        _accountsBox.put(updatedSelected.id, updatedSelected);
      }
    }
  }

  Future<void> _onSetDefaultAccount(
      SetDefaultAccount event, Emitter<AccountState> emit) async {
    try {
      await _apiService.setDefaultAccount(event.accountId);

      if (state is AccountsLoaded) {
        final currentState = state as AccountsLoaded;
        final updatedAccounts = currentState.accounts.map((account) {
          return account.copyWith(isDefault: account.id == event.accountId);
        }).toList();

        emit(currentState.copyWith(accounts: updatedAccounts));
      }
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onDepositRequested(
      DepositRequested event, Emitter<AccountState> emit) async {
    try {
      emit(DepositProcessing());

      final response = await _apiService.initiateDeposit(event.amountKes);

      emit(DepositInitiated(
        checkoutRequestId: response['checkout_request_id'],
        amount: event.amountKes,
      ));
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onWithdrawalRequested(
      WithdrawalRequested event, Emitter<AccountState> emit) async {
    try {
      emit(WithdrawalProcessing());

      final response = await _apiService.requestWithdrawal(
        event.amountUsd,
        phoneNumber: event.phoneNumber,
      );

      emit(WithdrawalRequestedState(
        requestId: response['request_id'],
        amount: event.amountUsd,
      ));
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadTransactionHistory(
      LoadTransactionHistory event, Emitter<AccountState> emit) async {
    try {
      final transactions = await _apiService.getTransactionHistory(
        limit: event.limit,
        offset: event.offset,
      );

      emit(TransactionHistoryLoaded(transactions: transactions));
    } catch (e) {
      emit(AccountError(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('invalid')) {
        return 'Invalid account credentials';
      } else if (message.contains('exists')) {
        return 'Account already connected';
      } else if (message.contains('insufficient')) {
        return 'Insufficient balance';
      } else if (message.contains('network')) {
        return 'Network error. Please check your connection';
      }
    }
    return 'Operation failed. Please try again';
  }

  @override
  Future<void> close() {
    _balanceSubscription?.cancel();
    _syncTimer?.cancel();
    return super.close();
  }
}
