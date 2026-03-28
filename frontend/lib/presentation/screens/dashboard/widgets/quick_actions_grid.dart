import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline,
        label: 'Deposit',
        color: AppTheme.mpesaGreen,
        onTap: () {
          // Navigate to deposit
        },
      ),
      _QuickAction(
        icon: Icons.remove_circle_outline,
        label: 'Withdraw',
        color: AppTheme.dangerRed,
        onTap: () {
          // Navigate to withdraw
        },
      ),
      _QuickAction(
        icon: Icons.notifications_active_outlined,
        label: 'Signals',
        color: AppTheme.warningOrange,
        onTap: () {
          // Navigate to signals
        },
      ),
      _QuickAction(
        icon: Icons.history,
        label: 'History',
        color: AppTheme.secondaryBlue,
        onTap: () {
          // Navigate to history
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((action) => _buildActionButton(action)).toList(),
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: action.color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              action.icon,
              color: action.color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
