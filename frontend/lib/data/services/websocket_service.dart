import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../../core/constants/app_constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _currentToken;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Stream Controllers
  final _balanceController = StreamController<Map<String, dynamic>>.broadcast();
  final _tradeController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _priceController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Public Streams
  Stream<Map<String, dynamic>> get balanceStream => _balanceController.stream;
  Stream<Map<String, dynamic>> get tradeStream => _tradeController.stream;
  Stream<Map<String, dynamic>> get signalStream => _signalController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get priceStream => _priceController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  void connect(String token) {
    if (_isConnected && _currentToken == token) return;

    _currentToken = token;
    _connect();
  }

  void _connect() {
    if (_currentToken == null || _currentToken!.isEmpty) {
      print('WebSocket: No token provided');
      return;
    }

    try {
      final wsUrl = '${AppConstants.wsBaseUrl}?token=$_currentToken';
      print('WebSocket: Connecting to $wsUrl');

      _channel = IOWebSocketChannel.connect(
        wsUrl,
        pingInterval: _pingInterval,
      );

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _startPingTimer();

      print('WebSocket: Connected successfully');
    } catch (e) {
      print('WebSocket: Connection error - $e');
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      _handleMessage(data);
    } catch (e) {
      print('WebSocket: Error parsing message - $e');
    }
  }

  void _onError(dynamic error) {
    print('WebSocket: Error - $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  void _onDone() {
    print('WebSocket: Connection closed');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];
    final payload = data['payload'];

    switch (type) {
      case 'balance_update':
        _balanceController.add(payload);
        break;
      case 'trade_update':
        _tradeController.add(payload);
        break;
      case 'new_signal':
        _signalController.add(payload);
        break;
      case 'signal_executed':
        _signalController.add({...payload, 'event': 'executed'});
        break;
      case 'notification':
        _notificationController.add(payload);
        break;
      case 'price_update':
        _priceController.add(payload);
        break;
      case 'trade_executed':
        _tradeController.add({...payload, 'event': 'executed'});
        _showTradeNotification(payload);
        break;
      case 'trade_closed':
        _tradeController.add({...payload, 'event': 'closed'});
        _showTradeClosedNotification(payload);
        break;
      case 'tp_sl_hit':
        _showProfitNotification(payload);
        break;
      case 'margin_call':
        _showMarginCallNotification(payload);
        break;
      case 'deposit_confirmed':
        _notificationController.add({
          'type': 'deposit_confirmed',
          ...payload,
        });
        break;
      case 'withdrawal_confirmed':
        _notificationController.add({
          'type': 'withdrawal_confirmed',
          ...payload,
        });
        break;
      case 'pong':
        // Heartbeat response
        break;
      default:
        print('WebSocket: Unknown message type - $type');
    }
  }

  void _showTradeNotification(Map<String, dynamic> trade) {
    final pair = trade['pair'] ?? 'Unknown';
    final direction = trade['direction'] ?? 'BUY';
    final lotSize = trade['lot_size'] ?? 0.0;

    _notificationController.add({
      'type': 'trade_opened',
      'title': 'Trade Executed',
      'body': '$direction $lotSize lots on $pair',
      'data': trade,
    });
  }

  void _showTradeClosedNotification(Map<String, dynamic> trade) {
    final pair = trade['pair'] ?? 'Unknown';
    final pnl = trade['final_pnl'] ?? 0.0;
    final isProfit = pnl > 0;

    _notificationController.add({
      'type': 'trade_closed',
      'title': 'Trade Closed',
      'body':
          '${isProfit ? 'Profit' : 'Loss'}: \$${pnl.toStringAsFixed(2)} on $pair',
      'data': trade,
    });
  }

  void _showProfitNotification(Map<String, dynamic> data) {
    final type = data['hit_type'] ?? 'TP'; // TP or SL
    final pair = data['pair'] ?? 'Unknown';
    final pnl = data['pnl'] ?? 0.0;

    _notificationController.add({
      'type': 'tp_sl_hit',
      'title': '$type Hit!',
      'body': '\$${pnl.toStringAsFixed(2)} on $pair',
      'data': data,
    });
  }

  void _showMarginCallNotification(Map<String, dynamic> data) {
    final marginLevel = data['margin_level'] ?? 0.0;

    _notificationController.add({
      'type': 'margin_call',
      'title': 'Margin Call Warning!',
      'body': 'Margin level at ${marginLevel.toStringAsFixed(1)}%',
      'data': data,
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('WebSocket: Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      print('WebSocket: Reconnecting (attempt $_reconnectAttempts)');
      _connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isConnected) {
        _send({'type': 'ping'});
      }
    });
  }

  void _send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  // Public methods to send messages
  void subscribeToPair(String pair) {
    _send({
      'type': 'subscribe_pair',
      'pair': pair,
    });
  }

  void unsubscribeFromPair(String pair) {
    _send({
      'type': 'unsubscribe_pair',
      'pair': pair,
    });
  }

  // Keep track of active subscriptions
  final Map<String, bool> _activeSubscriptions = {};

  void subscribeToAccount(String accountId) {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({
        'type': 'subscribe',
        'channel': 'account_updates',
        'account_id': accountId,
      }));
      _activeSubscriptions[accountId] = true;
      print('WebSocket: Subscribed to account $accountId');
    } else {
      print('WebSocket: Not connected, cannot subscribe to account $accountId');
    }
  }

  void unsubscribeFromAccount(String accountId) {
    if (_isConnected && _activeSubscriptions.containsKey(accountId)) {
      _channel?.sink.add(jsonEncode({
        'type': 'unsubscribe',
        'channel': 'account_updates',
        'account_id': accountId,
      }));
      _activeSubscriptions.remove(accountId);
      print('WebSocket: Unsubscribed from account $accountId');
    } else {
      print(
          'WebSocket: Cannot unsubscribe, account $accountId not active or not connected');
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionController.add(false);
    _currentToken = null;
    _activeSubscriptions.clear();
    print('WebSocket: Disconnected');
  }

  void dispose() {
    disconnect();
    _balanceController.close();
    _tradeController.close();
    _signalController.close();
    _notificationController.close();
    _priceController.close();
    _connectionController.close();
  }
}
