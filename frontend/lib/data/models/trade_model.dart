import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'trade_model.g.dart';

@HiveType(typeId: 3)
class TradeModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String signalId;
  
  @HiveField(2)
  final String accountId;
  
  @HiveField(3)
  final int brokerTicket;
  
  @HiveField(4)
  final String pair;
  
  @HiveField(5)
  final String direction;
  
  @HiveField(6)
  final double entryPrice;
  
  @HiveField(7)
  final double lotSize;
  
  @HiveField(8)
  final double stopLoss;
  
  @HiveField(9)
  final double takeProfit;
  
  @HiveField(10)
  final double? currentPrice;
  
  @HiveField(11)
  final double? floatingPnl;
  
  @HiveField(12)
  final String status; // 'OPEN', 'CLOSED', 'MODIFIED'
  
  @HiveField(13)
  final DateTime openedAt;
  
  @HiveField(14)
  final DateTime? closedAt;
  
  @HiveField(15)
  final double? closedPrice;
  
  @HiveField(16)
  final double? finalPnl;
  
  @HiveField(17)
  final String? closeReason;
  
  @HiveField(18)
  final List<Map<String, dynamic>>? partialCloses;
  
  @HiveField(19)
  final double? commission;
  
  @HiveField(20)
  final double? swap;
  
  @HiveField(21)
  final String? comment;
  
  @HiveField(22)
  final double? takeProfit2;
  
  @HiveField(23)
  final double? takeProfit3;
  
  @HiveField(24)
  final double? originalStopLoss;
  
  @HiveField(25)
  final double? originalTakeProfit;

  TradeModel({
    required this.id,
    required this.signalId,
    required this.accountId,
    required this.brokerTicket,
    required this.pair,
    required this.direction,
    required this.entryPrice,
    required this.lotSize,
    required this.stopLoss,
    required this.takeProfit,
    this.currentPrice,
    this.floatingPnl,
    this.status = 'OPEN',
    required this.openedAt,
    this.closedAt,
    this.closedPrice,
    this.finalPnl,
    this.closeReason,
    this.partialCloses,
    this.commission,
    this.swap,
    this.comment,
    this.takeProfit2,
    this.takeProfit3,
    this.originalStopLoss,
    this.originalTakeProfit,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'] ?? '',
      signalId: json['signal_id'] ?? '',
      accountId: json['account_id'] ?? '',
      brokerTicket: json['broker_ticket'] ?? 0,
      pair: json['pair'] ?? '',
      direction: json['direction'] ?? 'BUY',
      entryPrice: (json['entry_price'] as num?)?.toDouble() ?? 0.0,
      lotSize: (json['lot_size'] as num?)?.toDouble() ?? 0.01,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      takeProfit: (json['take_profit'] as num?)?.toDouble() ?? 0.0,
      currentPrice: json['current_price']?.toDouble(),
      floatingPnl: json['floating_pnl']?.toDouble(),
      status: json['status'] ?? 'OPEN',
      openedAt: json['opened_at'] != null 
          ? DateTime.parse(json['opened_at']) 
          : DateTime.now(),
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at']) 
          : null,
      closedPrice: json['closed_price']?.toDouble(),
      finalPnl: json['final_pnl']?.toDouble(),
      closeReason: json['close_reason'],
      partialCloses: json['partial_closes']?.cast<Map<String, dynamic>>(),
      commission: json['commission']?.toDouble(),
      swap: json['swap']?.toDouble(),
      comment: json['comment'],
      takeProfit2: json['take_profit_2']?.toDouble(),
      takeProfit3: json['take_profit_3']?.toDouble(),
      originalStopLoss: json['original_sl']?.toDouble(),
      originalTakeProfit: json['original_tp']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'signal_id': signalId,
    'account_id': accountId,
    'broker_ticket': brokerTicket,
    'pair': pair,
    'direction': direction,
    'entry_price': entryPrice,
    'lot_size': lotSize,
    'stop_loss': stopLoss,
    'take_profit': takeProfit,
    'current_price': currentPrice,
    'floating_pnl': floatingPnl,
    'status': status,
    'opened_at': openedAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'closed_price': closedPrice,
    'final_pnl': finalPnl,
    'close_reason': closeReason,
    'partial_closes': partialCloses,
    'commission': commission,
    'swap': swap,
    'comment': comment,
    'take_profit_2': takeProfit2,
    'take_profit_3': takeProfit3,
    'original_sl': originalStopLoss,
    'original_tp': originalTakeProfit,
  };

  TradeModel copyWith({
    String? id,
    String? signalId,
    String? accountId,
    int? brokerTicket,
    String? pair,
    String? direction,
    double? entryPrice,
    double? lotSize,
    double? stopLoss,
    double? takeProfit,
    double? currentPrice,
    double? floatingPnl,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    double? closedPrice,
    double? finalPnl,
    String? closeReason,
    List<Map<String, dynamic>>? partialCloses,
    double? commission,
    double? swap,
    String? comment,
    double? takeProfit2,
    double? takeProfit3,
    double? originalStopLoss,
    double? originalTakeProfit,
  }) {
    return TradeModel(
      id: id ?? this.id,
      signalId: signalId ?? this.signalId,
      accountId: accountId ?? this.accountId,
      brokerTicket: brokerTicket ?? this.brokerTicket,
      pair: pair ?? this.pair,
      direction: direction ?? this.direction,
      entryPrice: entryPrice ?? this.entryPrice,
      lotSize: lotSize ?? this.lotSize,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      currentPrice: currentPrice ?? this.currentPrice,
      floatingPnl: floatingPnl ?? this.floatingPnl,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      closedPrice: closedPrice ?? this.closedPrice,
      finalPnl: finalPnl ?? this.finalPnl,
      closeReason: closeReason ?? this.closeReason,
      partialCloses: partialCloses ?? this.partialCloses,
      commission: commission ?? this.commission,
      swap: swap ?? this.swap,
      comment: comment ?? this.comment,
      takeProfit2: takeProfit2 ?? this.takeProfit2,
      takeProfit3: takeProfit3 ?? this.takeProfit3,
      originalStopLoss: originalStopLoss ?? this.originalStopLoss,
      originalTakeProfit: originalTakeProfit ?? this.originalTakeProfit,
    );
  }

  double get pipsDistance {
    if (currentPrice == null) return 0.0;
    return direction == 'BUY' 
        ? currentPrice! - entryPrice
        : entryPrice - currentPrice!;
  }
      
  bool get isProfit => (floatingPnl ?? 0) > 0;
  
  bool get isLoss => (floatingPnl ?? 0) < 0;
  
  double get progressToTp {
    if (currentPrice == null) return 0.0;
    final totalDistance = (takeProfit - entryPrice).abs();
    if (totalDistance == 0) return 0.0;
    final currentDistance = (currentPrice! - entryPrice).abs();
    return (currentDistance / totalDistance).clamp(0.0, 1.0);
  }
  
  double get progressToSl {
    if (currentPrice == null) return 0.0;
    final totalDistance = (stopLoss - entryPrice).abs();
    if (totalDistance == 0) return 0.0;
    final currentDistance = (currentPrice! - entryPrice).abs();
    return (currentDistance / totalDistance).clamp(0.0, 1.0);
  }
  
  double get riskRewardRatio {
    final risk = (entryPrice - stopLoss).abs();
    final reward = (takeProfit - entryPrice).abs();
    if (risk == 0) return 0.0;
    return reward / risk;
  }
  
  Color get pnlColor {
    final pnl = floatingPnl ?? 0;
    if (pnl > 0) return Colors.green;
    if (pnl < 0) return Colors.red;
    return Colors.grey;
  }
  
  String get formattedPnl {
    final pnl = floatingPnl ?? 0;
    final sign = pnl >= 0 ? '+' : '';
    return '\$$sign${pnl.toStringAsFixed(2)}';
  }
  
  String get formattedFinalPnl {
    final pnl = finalPnl ?? 0;
    final sign = pnl >= 0 ? '+' : '';
    return '\$$sign${pnl.toStringAsFixed(2)}';
  }
  
  bool get isOpen => status == 'OPEN';
  
  bool get isClosed => status == 'CLOSED';
  
  String get formattedPair => pair.length > 6 ? pair : '${pair.substring(0, 3)}/${pair.substring(3)}';
  
  String get duration {
    final endTime = closedAt ?? DateTime.now();
    final diff = endTime.difference(openedAt);
    
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }
  
  double get totalCost => (commission ?? 0) + (swap ?? 0);
  
  String get formattedLotSize => lotSize.toStringAsFixed(2);
}
