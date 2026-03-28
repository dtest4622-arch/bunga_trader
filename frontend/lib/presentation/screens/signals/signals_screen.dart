import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/signal_model.dart';
import '../../blocs/signal/signal_bloc.dart';
import '../../blocs/trading/trading_bloc.dart' hide SignalsLoaded, LoadSignals;
import '../../blocs/account/account_bloc.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Trading Signals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: BlocBuilder<SignalBloc, SignalState>(
        builder: (context, state) {
          if (state is SignalsLoaded) {
            final signals = state.displaySignals;
            
            if (signals.isEmpty) {
              return _buildEmptyState();
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SignalBloc>().add(const LoadSignals());
              },
              color: AppTheme.primaryPurple,
              backgroundColor: AppTheme.cardBackground,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: signals.length,
                itemBuilder: (context, index) {
                  return _buildSignalCard(signals[index]);
                },
              ),
            );
          }
          
          if (state is SignalLoading) {
            return _buildLoadingState();
          }
          
          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildSignalCard(SignalModel signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: signal.directionColor.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  signal.directionIcon,
                  color: signal.directionColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.formattedPair,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signal.groupName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: signal.confidenceColor.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${signal.confidenceScore}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: signal.confidenceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Signal Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailColumn('Direction', signal.direction, signal.directionColor),
              _buildDetailColumn('Lot Size', signal.aiLotSize.toStringAsFixed(2), AppTheme.textPrimary),
              _buildDetailColumn('Risk', '${signal.riskPercent.toStringAsFixed(1)}%', AppTheme.warningOrange),
            ],
          ),
          if (signal.entryPrice != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Entry', signal.entryPrice!.toStringAsFixed(5), AppTheme.textPrimary),
                _buildDetailColumn('SL', signal.aiStopLoss.toStringAsFixed(5), AppTheme.dangerRed),
                _buildDetailColumn('TP', signal.aiTakeProfit.toStringAsFixed(5), AppTheme.buyGreen),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Action Buttons
          if (signal.isPending)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _executeSignal(signal),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Execute'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.buyGreen,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectSignal(signal),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed,
                      side: const BorderSide(color: AppTheme.dangerRed),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _executeSignal(SignalModel signal) {
    final accountState = context.read<AccountBloc>().state;
    if (accountState is AccountsLoaded && accountState.selectedAccount != null) {
      context.read<TradingBloc>().add(ExecuteSignal(
        signalId: signal.id,
        accountId: accountState.selectedAccount!.id,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trading account first'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  void _rejectSignal(SignalModel signal) {
    context.read<TradingBloc>().add(RejectSignal(signalId: signal.id));
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Signals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  'ALL',
                  'PENDING',
                  'EXECUTED',
                  'REJECTED',
                ].map((filter) => ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: AppTheme.primaryPurple,
                  backgroundColor: AppTheme.darkBackground,
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter 
                        ? Colors.white 
                        : AppTheme.textSecondary,
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Signals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Signals will appear here when available',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SignalBloc>().add(const LoadSignals());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
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
