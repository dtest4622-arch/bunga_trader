import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _apiDio;
  late Dio _supabaseDio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    // Backend API for authentication and business logic
    _apiDio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Supabase REST API for data access (profiles, accounts, signals, etc.)
    _supabaseDio = Dio(BaseOptions(
      baseUrl: '${AppConstants.supabaseUrl}/rest/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'apikey': AppConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
      },
    ));

    // Setup interceptors for both clients
    _setupInterceptors();
  }

  // Interceptors
  void _setupInterceptors() {
    _apiDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('[API Request] ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '[API Response] ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('[API Error] ${error.type} - ${error.message}');
          if (error.response?.statusCode == 401) {
            // Token expired, try to refresh
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await getAuthToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              return handler.resolve(await _apiDio.fetch(error.requestOptions));
            }
          }
          return handler.next(error);
        },
      ),
    );

    _supabaseDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          print('[Supabase Error] ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
    _apiDio.options.headers['Authorization'] = 'Bearer $token';
    _supabaseDio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.authTokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.authTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    _apiDio.options.headers.remove('Authorization');
    _supabaseDio.options.headers.remove('Authorization');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _apiDio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.data['token'] != null) {
        await setAuthToken(response.data['token']);
        if (response.data['refresh_token'] != null) {
          await setRefreshToken(response.data['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiDio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    if (response.data['token'] != null) {
      final accessToken = response.data['token'];
      final refreshToken = response.data['refresh_token'];

      await setAuthToken(accessToken);
      if (refreshToken != null) {
        await setRefreshToken(refreshToken);
      }

      // Return user data from response
      return response.data['user'] ?? response.data;
    }

    return response.data;
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String phoneNumber, String mpesaNumber,
      {String? fullName}) async {
    // Register via backend API
    final response = await _apiDio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'mpesa_number': mpesaNumber,
      'full_name': fullName,
    });

    return response.data;
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getAuthToken();
      if (token != null) {
        await _apiDio.post('/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $token'}));
      }
      await clearTokens();
      return {'success': true};
    } catch (e) {
      await clearTokens();
      return {'success': true};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.get('/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.put('/auth/profile',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    return response.data;
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/auth/change-password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    return response.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _apiDio.post('/auth/forgot-password', data: {
      'email': email,
    });
    return response.data;
  }

  // ==================== ACCOUNTS ====================

  Future<List<Map<String, dynamic>>> getTradingAccounts() async {
    final token = await getAuthToken();
    if (token == null) return [];

    final response = await _supabaseDio.get('/trading_accounts',
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getTradingAccount(String accountId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.get('/trading_accounts',
        queryParameters: {'id': 'eq.$accountId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data[0];
  }

  Future<Map<String, dynamic>> connectBrokerAccount(
      String broker, String login, String password, String server,
      {String platform = 'MT5', String? accountType}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.post('/trading_accounts',
        data: {
          'broker': broker,
          'login': login,
          'password': password,
          'server': server,
          'platform': platform,
          if (accountType != null) 'account_type': accountType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<void> disconnectBrokerAccount(String accountId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    await _supabaseDio.delete('/trading_accounts',
        queryParameters: {'id': 'eq.$accountId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  Future<void> switchActiveAccount(String accountId) async {
    // This would require updating user preferences - simplified for now
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<Map<String, dynamic>> setDefaultAccount(String accountId) async {
    return await updateProfile({'default_account_id': accountId});
  }

  Future<Map<String, dynamic>> syncAccount(String accountId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    // This would trigger a sync with MT5 - simplified for now
    return {'synced': true, 'account_id': accountId};
  }

  // ==================== SIGNALS ====================

  Future<List<Map<String, dynamic>>> getSignals({
    int limit = 50,
    int offset = 0,
    String? status,
    String? pair,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'order': 'created_at.desc',
      if (status != null) 'status': 'eq.$status',
      if (pair != null) 'pair': 'eq.$pair',
    };

    final response =
        await _supabaseDio.get('/signals', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getSignal(String signalId) async {
    final response = await _supabaseDio
        .get('/signals', queryParameters: {'id': 'eq.$signalId'});
    return response.data[0];
  }

  Future<Map<String, dynamic>> executeSignal(
    String signalId,
    String accountId, {
    bool autoExecute = false,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.post('/executed_signals',
        data: {
          'signal_id': signalId,
          'account_id': accountId,
          'auto_execute': autoExecute,
          'executed_at': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<void> rejectSignal(String signalId, {String? reason}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    await _supabaseDio.patch('/signals',
        data: {'status': 'rejected', 'rejection_reason': reason},
        queryParameters: {'id': 'eq.$signalId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
  }

  // ==================== TRADES ====================

  Future<List<Map<String, dynamic>>> getActiveTrades() async {
    final token = await getAuthToken();
    if (token == null) return [];

    final response = await _supabaseDio.get('/trades',
        queryParameters: {'status': 'eq.open', 'order': 'created_at.desc'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getTradeHistory({
    int limit = 50,
    int offset = 0,
    DateTime? from,
    DateTime? to,
  }) async {
    final token = await getAuthToken();
    if (token == null) return [];

    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'order': 'created_at.desc',
      if (from != null) 'created_at': 'gte.${from.toIso8601String()}',
      if (to != null) 'created_at': 'lte.${to.toIso8601String()}',
    };

    final response = await _supabaseDio.get('/trades',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getTrade(String tradeId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.get('/trades',
        queryParameters: {'id': 'eq.$tradeId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data[0];
  }

  Future<Map<String, dynamic>> closeTrade(
    String tradeId, {
    double? partialPercent,
    String? reason,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.patch('/trades',
        data: {
          'status': 'closed',
          'closed_at': DateTime.now().toIso8601String(),
          if (partialPercent != null) 'closed_percent': partialPercent,
          if (reason != null) 'close_reason': reason,
        },
        queryParameters: {'id': 'eq.$tradeId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<Map<String, dynamic>> modifyTrade(
    String tradeId, {
    double? newStopLoss,
    double? newTakeProfit,
    double? newTakeProfit2,
    double? newTakeProfit3,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.patch('/trades',
        data: {
          if (newStopLoss != null) 'stop_loss': newStopLoss,
          if (newTakeProfit != null) 'take_profit': newTakeProfit,
          if (newTakeProfit2 != null) 'take_profit_2': newTakeProfit2,
          if (newTakeProfit3 != null) 'take_profit_3': newTakeProfit3,
        },
        queryParameters: {'id': 'eq.$tradeId'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<Map<String, dynamic>> closeAllTrades({String? pair}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    // Get all open trades
    final queryParams = <String, dynamic>{'status': 'eq.open'};
    if (pair != null) {
      queryParams['pair'] = 'eq.$pair';
    }

    final response = await _supabaseDio.get('/trades',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    final trades = List<Map<String, dynamic>>.from(response.data);
    for (var trade in trades) {
      await _supabaseDio.patch('/trades',
          data: {
            'status': 'closed',
            'closed_at': DateTime.now().toIso8601String()
          },
          queryParameters: {'id': 'eq.${trade["id"]}'},
          options: Options(headers: {'Authorization': 'Bearer $token'}));
    }

    return {'closed_count': trades.length};
  }

  // ==================== M-PESA ====================

  Future<Map<String, dynamic>> initiateDeposit(int amountKes) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.post('/mpesa_deposits',
        data: {
          'amount_kes': amountKes,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<Map<String, dynamic>> checkDepositStatus(
      String checkoutRequestId) async {
    final response = await _supabaseDio.get('/mpesa_deposits',
        queryParameters: {'checkout_request_id': 'eq.$checkoutRequestId'});
    return response.data[0] ?? {'status': 'unknown'};
  }

  Future<Map<String, dynamic>> requestWithdrawal(
    double amountUsd, {
    String? phoneNumber,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.post('/mpesa_withdrawals',
        data: {
          'amount_usd': amountUsd,
          'phone_number': phoneNumber,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}));
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final token = await getAuthToken();
    if (token == null) return [];

    // Combine deposits and withdrawals into transactions
    final deposits = await _supabaseDio.get('/mpesa_deposits',
        queryParameters: {'limit': limit, 'order': 'created_at.desc'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    final withdrawals = await _supabaseDio.get('/mpesa_withdrawals',
        queryParameters: {'limit': limit, 'order': 'created_at.desc'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    final List<Map<String, dynamic>> transactions = [];

    for (var d in deposits.data) {
      transactions.add({
        ...d,
        'type': 'deposit',
      });
    }

    for (var w in withdrawals.data) {
      transactions.add({
        ...w,
        'type': 'withdrawal',
      });
    }

    transactions.sort((a, b) => DateTime.parse(b['created_at'])
        .compareTo(DateTime.parse(a['created_at'])));

    return transactions.take(limit).toList();
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>> getCompoundingSettings() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.get('/user_settings',
        queryParameters: {'key': 'eq.compounding'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    if (response.data.isNotEmpty) {
      return response.data[0]['value'] ?? {};
    }
    return {};
  }

  Future<void> updateCompoundingSettings(Map<String, dynamic> settings) async {
    await updateProfile({'compounding_settings': settings});
  }

  Future<Map<String, dynamic>> getRiskSettings() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _supabaseDio.get('/user_settings',
        queryParameters: {'key': 'eq.risk'},
        options: Options(headers: {'Authorization': 'Bearer $token'}));

    if (response.data.isNotEmpty) {
      return response.data[0]['value'] ?? {};
    }
    return {};
  }

  Future<void> updateRiskSettings(Map<String, dynamic> settings) async {
    await updateProfile({'risk_settings': settings});
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    return {
      'push_enabled': true,
      'signal_alerts': true,
      'trade_alerts': true,
      'deposit_alerts': true,
    };
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    await updateProfile({'notification_settings': settings});
  }

  // ==================== ANALYTICS ====================

  Future<Map<String, dynamic>> getTradingStats({
    DateTime? from,
    DateTime? to,
    String? accountId,
  }) async {
    final queryParams = <String, dynamic>{
      if (from != null) 'created_at': 'gte.${from.toIso8601String()}',
      if (to != null) 'created_at': 'lte.${to.toIso8601String()}',
      if (accountId != null) 'account_id': 'eq.$accountId',
    };

    final tradesResponse =
        await _supabaseDio.get('/trades', queryParameters: queryParams);
    final trades = List<Map<String, dynamic>>.from(tradesResponse.data);

    double totalPnl = 0;
    int winningTrades = 0;
    int losingTrades = 0;

    for (var trade in trades) {
      final pnl = (trade['profit'] ?? 0).toDouble();
      totalPnl += pnl;
      if (pnl > 0) {
        winningTrades++;
      } else if (pnl < 0) {
        losingTrades++;
      }
    }

    return {
      'total_trades': trades.length,
      'winning_trades': winningTrades,
      'losing_trades': losingTrades,
      'total_pnl': totalPnl,
      'win_rate': trades.isNotEmpty ? winningTrades / trades.length : 0,
    };
  }

  Future<Map<String, dynamic>> getDailyPnl({
    required int days,
    String? accountId,
  }) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final stats = await getTradingStats(from: from, accountId: accountId);

    return {
      'daily_pnl': stats['total_pnl'] ?? 0,
      'period': days,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSignals({
    int limit = 10,
    String? accountId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'status': 'eq.closed',
      'order': 'profit.desc',
    };

    final response =
        await _supabaseDio.get('/signals', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }
}
