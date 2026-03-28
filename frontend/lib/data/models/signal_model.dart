import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'signal_model.g.dart';

@HiveType(typeId: 2)
class SignalModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String groupId;
  
  @HiveField(2)
  final String groupName;
  
  @HiveField(3)
  final String rawMessage;
  
  @HiveField(4)
  final String pair;
  
  @HiveField(5)
  final String direction; // 'BUY', 'SELL'
  
  @HiveField(6)
  final double? entryPrice;
  
  @HiveField(7)
  final double? stopLoss;
  
  @HiveField(8)
  final double? takeProfit;
  
  @HiveField(9)
  final double? takeProfit2;
  
  @HiveField(10)
  final double? takeProfit3;
  
  @HiveField(11)
  final double aiLotSize;
  
  @HiveField(12)
  final double aiStopLoss;
  
  @HiveField(13)
  final double aiTakeProfit;
  
  @HiveField(14)
  final double riskPercent;
  
  @HiveField(15)
  final int confidenceScore; // 0-100
  
  @HiveField(16)
  final String status; // 'PENDING', 'EXECUTED', 'REJECTED', 'EXPIRED', 'CLOSED'
  
  @HiveField(17)
  final DateTime createdAt;
  
  @HiveField(18)
  final DateTime? executedAt;
  
  @HiveField(19)
  final DateTime? expiredAt;
  
  @HiveField(20)
  final String? tradeId;
  
  @HiveField(21)
  final String? rejectionReason;
  
  @HiveField(22)
  final double? rrRatio;
  
  @HiveField(23)
  final String? timeFrame;
  
  @HiveField(24)
  final String? analysis;

  SignalModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.rawMessage,
    required this.pair,
    required this.direction,
    this.entryPrice,
    this.stopLoss,
    this.takeProfit,
    this.takeProfit2,
    this.takeProfit3,
    required this.aiLotSize,
    required this.aiStopLoss,
    required this.aiTakeProfit,
    required this.riskPercent,
    required this.confidenceScore,
    this.status = 'PENDING',
    required this.createdAt,
    this.executedAt,
    this.expiredAt,
    this.tradeId,
    this.rejectionReason,
    this.rrRatio,
    this.timeFrame,
    this.analysis,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    return SignalModel(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? 'Unknown Group',
      rawMessage: json['raw_message'] ?? '',
      pair: json['pair'] ?? '',
      direction: json['direction'] ?? 'BUY',
      entryPrice: json['entry_price']?.toDouble(),
      stopLoss: json['stop_loss']?.toDouble(),
      takeProfit: json['take_profit']?.toDouble(),
      takeProfit2: json['take_profit_2']?.toDouble(),
      takeProfit3: json['take_profit_3']?.toDouble(),
      aiLotSize: (json['ai_lot_size'] as num?)?.toDouble() ?? 0.01,
      aiStopLoss: (json['ai_sl'] as num?)?.toDouble() ?? 0.0,
      aiTakeProfit: (json['ai_tp'] as num?)?.toDouble() ?? 0.0,
      riskPercent: (json['risk_percent'] as num?)?.toDouble() ?? 1.0,
      confidenceScore: json['confidence_score'] ?? 50,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      executedAt: json['executed_at'] != null 
          ? DateTime.parse(json['executed_at']) 
          : null,
      expiredAt: json['expired_at'] != null 
          ? DateTime.parse(json['expired_at']) 
          : null,
      tradeId: json['trade_id'],
      rejectionReason: json['rejection_reason'],
      rrRatio: json['rr_ratio']?.toDouble(),
      timeFrame: json['time_frame'],
      analysis: json['analysis'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'group_name': groupName,
    'raw_message': rawMessage,
    'pair': pair,
    'direction': direction,
    'entry_price': entryPrice,
    'stop_loss': stopLoss,
    'take_profit': takeProfit,
    'take_profit_2': takeProfit2,
    'take_profit_3': takeProfit3,
    'ai_lot_size': aiLotSize,
    'ai_sl': aiStopLoss,
    'ai_tp': aiTakeProfit,
    'risk_percent': riskPercent,
    'confidence_score': confidenceScore,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'executed_at': executedAt?.toIso8601String(),
    'expired_at': expiredAt?.toIso8601String(),
    'trade_id': tradeId,
    'rejection_reason': rejectionReason,
    'rr_ratio': rrRatio,
    'time_frame': timeFrame,
    'analysis': analysis,
  };

  SignalModel copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? rawMessage,
    String? pair,
    String? direction,
    double? entryPrice,
    double? stopLoss,
    double? takeProfit,
    double? takeProfit2,
    double? takeProfit3,
    double? aiLotSize,
    double? aiStopLoss,
    double? aiTakeProfit,
    double? riskPercent,
    int? confidenceScore,
    String? status,
    DateTime? createdAt,
    DateTime? executedAt,
    DateTime? expiredAt,
    String? tradeId,
    String? rejectionReason,
    double? rrRatio,
    String? timeFrame,
    String? analysis,
  }) {
    return SignalModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      rawMessage: rawMessage ?? this.rawMessage,
      pair: pair ?? this.pair,
      direction: direction ?? this.direction,
      entryPrice: entryPrice ?? this.entryPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      takeProfit2: takeProfit2 ?? this.takeProfit2,
      takeProfit3: takeProfit3 ?? this.takeProfit3,
      aiLotSize: aiLotSize ?? this.aiLotSize,
      aiStopLoss: aiStopLoss ?? this.aiStopLoss,
      aiTakeProfit: aiTakeProfit ?? this.aiTakeProfit,
      riskPercent: riskPercent ?? this.riskPercent,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      executedAt: executedAt ?? this.executedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      tradeId: tradeId ?? this.tradeId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rrRatio: rrRatio ?? this.rrRatio,
      timeFrame: timeFrame ?? this.timeFrame,
      analysis: analysis ?? this.analysis,
    );
  }

  bool get isHighConfidence => confidenceScore >= 75;
  
  bool get isMediumConfidence => confidenceScore >= 50 && confidenceScore < 75;
  
  bool get isLowConfidence => confidenceScore < 50;
  
  Color get confidenceColor {
    if (isHighConfidence) return Colors.green;
    if (isMediumConfidence) return Colors.orange;
    return Colors.red;
  }
  
  Color get directionColor => direction == 'BUY' 
      ? const Color(0xFF00B894) 
      : const Color(0xFFFF7675);
  
  IconData get directionIcon => direction == 'BUY' 
      ? Icons.trending_up 
      : Icons.trending_down;
  
  bool get isPending => status == 'PENDING';
  
  bool get isExecuted => status == 'EXECUTED';
  
  bool get isExpired => status == 'EXPIRED';
  
  bool get isRejected => status == 'REJECTED';
  
  bool get canExecute => isPending && !isExpired;
  
  String get formattedPair => pair.length > 6 ? pair : '${pair.substring(0, 3)}/${pair.substring(3)}';
  
  double? get potentialPips {
    if (entryPrice != null && takeProfit != null) {
      return (takeProfit! - entryPrice!).abs();
    }
    return null;
  }
  
  double? get riskPips {
    if (entryPrice != null && stopLoss != null) {
      return (entryPrice! - stopLoss!).abs();
    }
    return null;
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
