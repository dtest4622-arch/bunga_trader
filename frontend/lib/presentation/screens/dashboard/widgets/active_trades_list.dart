import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/trade_model.dart';
import '../../../blocs/trading/trading_bloc.dart';

class ActiveTradesList extends StatelessWidget {
  const ActiveTradesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TradingBloc, TradingState>(
      builder: (context, state) {
        if (state is TradesLoaded) {
          final activeTrades = state.activeTrades.take(3).toList();
          
          if (activeTrades.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            children: activeTrades.map((trade) => _buildTradeCard(trade)).toList(),
          );
        }
        
        if (state is TradingLoading) {
          return _buildLoadingState();
        }
        
        return _buildEmptyState();
      },
    );
  }

  Widget _buildTradeCard(TradeModel trade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trade.isProfit
              ? _colorWithOpacity(AppTheme.buyGreen, 0.3)
              : trade.isLoss
                  ? _colorWithOpacity(AppTheme.sellRed, 0.3)
                  : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trade.direction == 'BUY'
                          ? _colorWithOpacity(AppTheme.buyGreen, 0.2)
                          : _colorWithOpacity(AppTheme.sellRed, 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trade.direction,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: trade.direction == 'BUY'
                            ? AppTheme.buyGreen
                            : AppTheme.sellRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    trade.formattedPair,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                trade.formattedPnl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: trade.pnlColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTradeInfo('Lot Size', trade.formattedLotSize),
              _buildTradeInfo('Entry', trade.entryPrice.toStringAsFixed(5)),
              _buildTradeInfo('Current', trade.currentPrice?.toStringAsFixed(5) ?? '-'),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar to TP
          if (trade.progressToTp > 0)
            LinearProgressIndicator(
              value: trade.progressToTp,
              backgroundColor: _colorWithOpacity(AppTheme.textSecondary, 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                trade.isProfit ? AppTheme.buyGreen : AppTheme.sellRed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No Active Trades',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Execute a signal to start trading',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Color _colorWithOpacity(Color color, double opacity) {
    return color.withValues(
      alpha: opacity,
    );
  }
}
