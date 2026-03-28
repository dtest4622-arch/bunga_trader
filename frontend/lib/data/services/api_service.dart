import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _apiDio;
  final _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _initializeDio();
  }

  void _initializeDio() {
    // Backend API for all requests (authentication, business logic, and data access)
    _apiDio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Setup interceptors
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
          print(
              '[API Request] ${options.method} ${options.path} - data=${options.data}');
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
  }

  Future<void> setAuthToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
    _apiDio.options.headers['Authorization'] = 'Bearer $token';
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
  // ==================== TRADING ACCOUNTS ====================

  Future<List<Map<String, dynamic>>> getTradingAccounts() async {
    final token = await getAuthToken();
    if (token == null) return [];

    final response = await _apiDio.get('/accounts');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getTradingAccount(String accountId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.get('/accounts/$accountId');
    return response.data;
  }

  Future<Map<String, dynamic>> connectBrokerAccount(
      String broker, String login, String password, String server,
      {String platform = 'MT5', String? accountType}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/accounts/connect', data: {
      'broker': broker,
      'login': login,
      'password': password,
      'server': server,
      'platform': platform,
      if (accountType != null) 'account_type': accountType,
    });
    return response.data;
  }

  Future<void> disconnectBrokerAccount(String accountId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    await _apiDio.delete('/accounts/$accountId');
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
      if (status != null) 'status': status,
      if (pair != null) 'pair': pair,
    };

    final response =
        await _apiDio.get('/signals', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getSignal(String signalId) async {
    final response = await _apiDio.get('/signals/$signalId');
    return response.data;
  }

  Future<Map<String, dynamic>> executeSignal(
    String signalId,
    String accountId, {
    bool autoExecute = false,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/signals/$signalId/execute', data: {
      'account_id': accountId,
      'auto_execute': autoExecute,
    });
    return response.data;
  }

  Future<void> rejectSignal(String signalId, {String? reason}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    await _apiDio.post('/signals/$signalId/reject', data: {'reason': reason});
  }

  // ==================== TRADES ====================

  Future<List<Map<String, dynamic>>> getActiveTrades() async {
    final token = await getAuthToken();
    if (token == null) return [];

    final response = await _apiDio.get('/trades/active');
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
      if (from != null) 'from_date': from.toIso8601String(),
      if (to != null) 'to_date': to.toIso8601String(),
    };

    final response =
        await _apiDio.get('/trades/history', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getTrade(String tradeId) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.get('/trades/$tradeId');
    return response.data;
  }

  Future<Map<String, dynamic>> closeTrade(
    String tradeId, {
    double? partialPercent,
    String? reason,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/trades/$tradeId/close', data: {
      if (partialPercent != null) 'partial_percent': partialPercent,
      if (reason != null) 'reason': reason,
    });
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

    final response = await _apiDio.patch('/trades/$tradeId', data: {
      if (newStopLoss != null) 'stop_loss': newStopLoss,
      if (newTakeProfit != null) 'take_profit': newTakeProfit,
      if (newTakeProfit2 != null) 'take_profit_2': newTakeProfit2,
      if (newTakeProfit3 != null) 'take_profit_3': newTakeProfit3,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> closeAllTrades({String? pair}) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/trades/close-all', data: {
      if (pair != null) 'pair': pair,
    });
    return response.data;
  }

  // ==================== M-PESA ====================

  Future<Map<String, dynamic>> initiateDeposit(int amountKes) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/mpesa/deposit', data: {
      'amount_kes': amountKes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkDepositStatus(
      String checkoutRequestId) async {
    final response = await _apiDio.get('/mpesa/deposit/$checkoutRequestId');
    return response.data ?? {'status': 'unknown'};
  }

  Future<Map<String, dynamic>> requestWithdrawal(
    double amountUsd, {
    String? phoneNumber,
  }) async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.post('/mpesa/withdrawal', data: {
      'amount_usd': amountUsd,
      'phone_number': phoneNumber,
    });
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final token = await getAuthToken();
    if (token == null) return [];

    final response = await _apiDio.get('/mpesa/transactions',
        queryParameters: {'limit': limit, 'offset': offset});
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ==================== SETTINGS ====================

  Future<Map<String, dynamic>> getCompoundingSettings() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.get('/settings/compounding');
    return response.data ?? {};
  }

  Future<void> updateCompoundingSettings(Map<String, dynamic> settings) async {
    await updateProfile({'compounding_settings': settings});
  }

  Future<Map<String, dynamic>> getRiskSettings() async {
    final token = await getAuthToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _apiDio.get('/settings/risk');
    return response.data ?? {};
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
      if (from != null) 'from_date': from.toIso8601String(),
      if (to != null) 'to_date': to.toIso8601String(),
      if (accountId != null) 'account_id': accountId,
    };

    final tradesResponse =
        await _apiDio.get('/trades', queryParameters: queryParams);
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
      if (accountId != null) 'account_id': accountId,
    };

    final response =
        await _apiDio.get('/signals', queryParameters: queryParams);
    return List<Map<String, dynamic>>.from(response.data);
  }
}
