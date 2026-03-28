import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'trading_account_model.g.dart';

@HiveType(typeId: 1)
class TradingAccountModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String broker; // 'exness', 'xm', 'hotforex', 'icmarkets'
  
  @HiveField(3)
  final String accountType; // 'CENT', 'STANDARD', 'RAW', 'ZERO', 'PRO'
  
  @HiveField(4)
  final String platform; // 'MT4', 'MT5'
  
  @HiveField(5)
  final String login;
  
  @HiveField(6)
  final String server;
  
  @HiveField(7)
  final int leverage;
  
  @HiveField(8)
  final double balance;
  
  @HiveField(9)
  final double equity;
  
  @HiveField(10)
  final double margin;
  
  @HiveField(11)
  final double freeMargin;
  
  @HiveField(12)
  final double marginLevel;
  
  @HiveField(13)
  final bool isActive;
  
  @HiveField(14)
  final bool isDemo;
  
  @HiveField(15)
  final bool isDefault;
  
  @HiveField(16)
  final DateTime lastSynced;
  
  @HiveField(17)
  final DateTime createdAt;
  
  @HiveField(18)
  final String? accountCurrency;
  
  @HiveField(19)
  final int openPositions;
  
  @HiveField(20)
  final double dailyPnl;

  TradingAccountModel({
    required this.id,
    required this.userId,
    required this.broker,
    required this.accountType,
    required this.platform,
    required this.login,
    required this.server,
    required this.leverage,
    this.balance = 0.0,
    this.equity = 0.0,
    this.margin = 0.0,
    this.freeMargin = 0.0,
    this.marginLevel = 0.0,
    this.isActive = true,
    this.isDemo = false,
    this.isDefault = false,
    required this.lastSynced,
    required this.createdAt,
    this.accountCurrency = 'USD',
    this.openPositions = 0,
    this.dailyPnl = 0.0,
  });

  factory TradingAccountModel.fromJson(Map<String, dynamic> json) {
    return TradingAccountModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      broker: json['broker'] ?? 'exness',
      accountType: json['account_type'] ?? 'STANDARD',
      platform: json['platform'] ?? 'MT5',
      login: json['login'] ?? '',
      server: json['server'] ?? '',
      leverage: json['leverage'] ?? 100,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      equity: (json['equity'] as num?)?.toDouble() ?? 0.0,
      margin: (json['margin'] as num?)?.toDouble() ?? 0.0,
      freeMargin: (json['free_margin'] as num?)?.toDouble() ?? 0.0,
      marginLevel: (json['margin_level'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      isDemo: json['is_demo'] ?? false,
      isDefault: json['is_default'] ?? false,
      lastSynced: json['last_synced'] != null 
          ? DateTime.parse(json['last_synced']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      accountCurrency: json['account_currency'] ?? 'USD',
      openPositions: json['open_positions'] ?? 0,
      dailyPnl: (json['daily_pnl'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'broker': broker,
    'account_type': accountType,
    'platform': platform,
    'login': login,
    'server': server,
    'leverage': leverage,
    'balance': balance,
    'equity': equity,
    'margin': margin,
    'free_margin': freeMargin,
    'margin_level': marginLevel,
    'is_active': isActive,
    'is_demo': isDemo,
    'is_default': isDefault,
    'last_synced': lastSynced.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'account_currency': accountCurrency,
    'open_positions': openPositions,
    'daily_pnl': dailyPnl,
  };

  TradingAccountModel copyWith({
    String? id,
    String? userId,
    String? broker,
    String? accountType,
    String? platform,
    String? login,
    String? server,
    int? leverage,
    double? balance,
    double? equity,
    double? margin,
    double? freeMargin,
    double? marginLevel,
    bool? isActive,
    bool? isDemo,
    bool? isDefault,
    DateTime? lastSynced,
    DateTime? createdAt,
    String? accountCurrency,
    int? openPositions,
    double? dailyPnl,
  }) {
    return TradingAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      broker: broker ?? this.broker,
      accountType: accountType ?? this.accountType,
      platform: platform ?? this.platform,
      login: login ?? this.login,
      server: server ?? this.server,
      leverage: leverage ?? this.leverage,
      balance: balance ?? this.balance,
      equity: equity ?? this.equity,
      margin: margin ?? this.margin,
      freeMargin: freeMargin ?? this.freeMargin,
      marginLevel: marginLevel ?? this.marginLevel,
      isActive: isActive ?? this.isActive,
      isDemo: isDemo ?? this.isDemo,
      isDefault: isDefault ?? this.isDefault,
      lastSynced: lastSynced ?? this.lastSynced,
      createdAt: createdAt ?? this.createdAt,
      accountCurrency: accountCurrency ?? this.accountCurrency,
      openPositions: openPositions ?? this.openPositions,
      dailyPnl: dailyPnl ?? this.dailyPnl,
    );
  }

  String get displayName => '$broker ${accountType.toUpperCase()}';
  
  String get formattedBalance => '\$${balance.toStringAsFixed(2)}';
  
  String get formattedEquity => '\$${equity.toStringAsFixed(2)}';
  
  String get formattedMarginLevel => '${marginLevel.toStringAsFixed(1)}%';
  
  Color get accountColor {
    if (isDemo) return Colors.orange;
    switch (accountType.toUpperCase()) {
      case 'CENT':
        return Colors.green;
      case 'RAW':
        return Colors.purple;
      case 'ZERO':
        return Colors.blue;
      case 'PRO':
        return Colors.amber;
      default:
        return Colors.cyan;
    }
  }

  bool get isMarginSafe => marginLevel > 100;
  
  bool get hasOpenPositions => openPositions > 0;
  
  double get profitLoss => equity - balance;
  
  bool get isInProfit => profitLoss > 0;
}
