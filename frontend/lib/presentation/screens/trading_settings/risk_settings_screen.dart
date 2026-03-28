import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class RiskSettingsScreen extends StatefulWidget {
  const RiskSettingsScreen({super.key});

  @override
  State<RiskSettingsScreen> createState() => _RiskSettingsScreenState();
}

class _RiskSettingsScreenState extends State<RiskSettingsScreen> {
  double _maxRiskPerTrade = 2.0;
  double _maxRiskPerDay = 5.0;
  double _stopLossPercentage = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Risk Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSliderField(
                  label: 'Max Risk Per Trade (%)',
                  value: _maxRiskPerTrade,
                  onChanged: (value) =>
                      setState(() => _maxRiskPerTrade = value),
                  min: 0.5,
                  max: 10.0,
                ),
                const SizedBox(height: 24),
                _buildSliderField(
                  label: 'Max Daily Risk Loss (%)',
                  value: _maxRiskPerDay,
                  onChanged: (value) => setState(() => _maxRiskPerDay = value),
                  min: 1.0,
                  max: 20.0,
                ),
                const SizedBox(height: 24),
                _buildSliderField(
                  label: 'Stop Loss Percentage (%)',
                  value: _stopLossPercentage,
                  onChanged: (value) =>
                      setState(() => _stopLossPercentage = value),
                  min: 0.5,
                  max: 5.0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Risk settings saved')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)}%',
              style: const TextStyle(
                color: AppTheme.primaryPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: 19,
          activeColor: AppTheme.primaryPurple,
          inactiveColor: AppTheme.textSecondary.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}
