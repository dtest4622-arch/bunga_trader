import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SignalPreferencesScreen extends StatefulWidget {
  const SignalPreferencesScreen({super.key});

  @override
  State<SignalPreferencesScreen> createState() =>
      _SignalPreferencesScreenState();
}

class _SignalPreferencesScreenState extends State<SignalPreferencesScreen> {
  bool _buySignals = true;
  bool _sellSignals = true;
  bool _strongSignalsOnly = false;
  String _minSignalStrength = 'medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Signal Preferences'),
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
              children: [
                SwitchListTile(
                  title: const Text(
                    'Buy Signals',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  value: _buySignals,
                  onChanged: (value) => setState(() => _buySignals = value),
                  activeThumbColor: AppTheme.primaryPurple,
                ),
                const Divider(color: AppTheme.textSecondary),
                SwitchListTile(
                  title: const Text(
                    'Sell Signals',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  value: _sellSignals,
                  onChanged: (value) => setState(() => _sellSignals = value),
                  activeThumbColor: AppTheme.primaryPurple,
                ),
                const Divider(color: AppTheme.textSecondary),
                SwitchListTile(
                  title: const Text(
                    'Strong Signals Only',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Only receive high-confidence signals',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  value: _strongSignalsOnly,
                  onChanged: (value) =>
                      setState(() => _strongSignalsOnly = value),
                  activeThumbColor: AppTheme.primaryPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Minimum Signal Strength',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _minSignalStrength,
                  onChanged: (value) =>
                      setState(() => _minSignalStrength = value!),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'very_high', child: Text('Very High')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signal preferences saved')),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }
}
