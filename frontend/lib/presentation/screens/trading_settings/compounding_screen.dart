import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CompoundingScreen extends StatefulWidget {
  const CompoundingScreen({super.key});

  @override
  State<CompoundingScreen> createState() => _CompoundingScreenState();
}

class _CompoundingScreenState extends State<CompoundingScreen> {
  bool _enableCompounding = true;
  double _compoundingPercentage = 50.0;
  String _compoundingFrequency = 'daily';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Compounding'),
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
                SwitchListTile(
                  title: const Text(
                    'Enable Compounding',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: const Text(
                    'Automatically reinvest profits',
                    style:
                        TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  value: _enableCompounding,
                  onChanged: (value) =>
                      setState(() => _enableCompounding = value),
                  activeThumbColor: AppTheme.primaryPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_enableCompounding)
            Column(
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
                      const Text(
                        'Compounding Percentage',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reinvest',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            '${_compoundingPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _compoundingPercentage,
                        onChanged: (value) =>
                            setState(() => _compoundingPercentage = value),
                        divisions: 10,
                        activeColor: AppTheme.primaryPurple,
                        inactiveColor:
                            AppTheme.textSecondary.withValues(alpha: 0.2),
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
                        'Compounding Frequency',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _compoundingFrequency,
                        onChanged: (value) =>
                            setState(() => _compoundingFrequency = value!),
                        items: const [
                          DropdownMenuItem(
                              value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(
                              value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Monthly')),
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
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compounding settings saved')),
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
}
