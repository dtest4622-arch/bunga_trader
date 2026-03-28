import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/trade_model.dart';
import '../../blocs/trading/trading_bloc.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Trades'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _showCloseAllDialog();
            },
            tooltip: 'Close All',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTradesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTradesTab() {
    return BlocBuilder<TradingBloc, TradingState>(
      builder: (context, state) {
        if (state is TradesLoaded) {
          final activeTrades = state.activeTrades;

          if (activeTrades.isEmpty) {
            return _buildEmptyState(
                'No Active Trades', 'Execute signals to open trades');
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TradingBloc>().add(LoadTrades());
            },
            color: AppTheme.primaryPurple,
            backgroundColor: AppTheme.cardBackground,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: activeTrades.length,
              itemBuilder: (context, index) {
                return _buildTradeCard(activeTrades[index], isActive: true);
              },
            ),
          );
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<TradingBloc, TradingState>(
      builder: (context, state) {
        if (state is TradesLoaded) {
          final history = state.tradeHistory;

          if (history.isEmpty) {
            return _buildEmptyState(
                'No Trade History', 'Your closed trades will appear here');
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TradingBloc>().add(LoadTrades());
            },
            color: AppTheme.primaryPurple,
            backgroundColor: AppTheme.cardBackground,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: history.length,
              itemBuilder: (context, index) {
                return _buildTradeCard(history[index], isActive: false);
              },
            ),
          );
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildTradeCard(TradeModel trade, {required bool isActive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trade.isProfit
              ? AppTheme.buyGreen.withAlpha((255 * 0.3).round())
              : trade.isLoss
                  ? AppTheme.sellRed.withAlpha((255 * 0.3).round())
                  : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trade.direction == 'BUY'
                          ? AppTheme.buyGreen.withAlpha((255 * 0.2).round())
                          : AppTheme.sellRed.withAlpha((255 * 0.2).round()),
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
                isActive ? trade.formattedPnl : trade.formattedFinalPnl,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? trade.pnlColor
                      : (trade.finalPnl ?? 0) >= 0
                          ? AppTheme.buyGreen
                          : AppTheme.sellRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTradeInfo('Lot Size', trade.formattedLotSize),
              _buildTradeInfo('Entry', trade.entryPrice.toStringAsFixed(5)),
              if (isActive && trade.currentPrice != null)
                _buildTradeInfo(
                    'Current', trade.currentPrice!.toStringAsFixed(5)),
              if (!isActive && trade.closedPrice != null)
                _buildTradeInfo('Close', trade.closedPrice!.toStringAsFixed(5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTradeInfo('SL', trade.stopLoss.toStringAsFixed(5)),
              _buildTradeInfo('TP', trade.takeProfit.toStringAsFixed(5)),
              _buildTradeInfo('Duration', trade.duration),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showModifyTradeDialog(trade),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCloseTradeDialog(trade),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRed,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTradeInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
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

  void _showModifyTradeDialog(TradeModel trade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modify Trade',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Stop Loss',
                  hintText: trade.stopLoss.toStringAsFixed(5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Take Profit',
                  hintText: trade.takeProfit.toStringAsFixed(5),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Modify trade
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCloseTradeDialog(TradeModel trade) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Close Trade',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: Text(
            'Are you sure you want to close this ${trade.direction} ${trade.formattedPair} trade?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TradingBloc>().add(CloseTrade(tradeId: trade.id));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showCloseAllDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Close All Trades',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to close all open trades?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<TradingBloc>().add(const CloseAllTrades());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Close All'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.show_chart,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
