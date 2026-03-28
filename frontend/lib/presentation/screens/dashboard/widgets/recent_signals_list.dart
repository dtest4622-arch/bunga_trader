import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/signal_model.dart';
import '../../../blocs/signal/signal_bloc.dart';

class RecentSignalsList extends StatelessWidget {
  const RecentSignalsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignalBloc, SignalState>(
      builder: (context, state) {
        if (state is SignalsLoaded) {
          final recentSignals = state.signals.take(3).toList();
          
          if (recentSignals.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            children: recentSignals.map((signal) => _buildSignalCard(signal)).toList(),
          );
        }
        
        if (state is SignalLoading) {
          return _buildLoadingState();
        }
        
        return _buildEmptyState();
      },
    );
  }

  Widget _buildSignalCard(SignalModel signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: signal.isPending
              ? _colorWithOpacity(AppTheme.primaryPurple, 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Direction Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _colorWithOpacity(signal.directionColor, 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              signal.directionIcon,
              color: signal.directionColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Signal Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      signal.formattedPair,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _colorWithOpacity(signal.confidenceColor, 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${signal.confidenceScore}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: signal.confidenceColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      signal.direction,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: signal.directionColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colorWithOpacity(AppTheme.textSecondary, 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      signal.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (signal.entryPrice != null)
                  Text(
                    'Entry: ${signal.entryPrice?.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _colorWithOpacity(_getStatusColor(signal.status), 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              signal.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(signal.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return AppTheme.warningOrange;
      case 'EXECUTED':
        return AppTheme.buyGreen;
      case 'REJECTED':
      case 'EXPIRED':
        return AppTheme.dangerRed;
      case 'CLOSED':
        return AppTheme.secondaryBlue;
      default:
        return AppTheme.textSecondary;
    }
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
            Icons.notifications_none,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No Signals Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'New signals will appear here',
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
