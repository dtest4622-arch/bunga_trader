import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class TwoFAScreen extends StatefulWidget {
  const TwoFAScreen({super.key});

  @override
  State<TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<TwoFAScreen> {
  bool _twoFAEnabled = false;
  String _method = 'authenticator';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
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
                const Text(
                  '2FA Status',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _twoFAEnabled
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _twoFAEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _twoFAEnabled ? Icons.check_circle : Icons.cancel,
                        color: _twoFAEnabled ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _twoFAEnabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color: _twoFAEnabled ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                  'Authentication Method',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_twoFAEnabled)
                  Column(
                    children: [
                      RadioListTile<String>(
                        value: 'authenticator',
                        groupValue: _method,
                        onChanged: (value) => setState(() => _method = value!),
                        title: const Text(
                          'Authenticator App',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: const Text(
                          'Use Google Authenticator or Authy',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        activeColor: AppTheme.primaryPurple,
                      ),
                      RadioListTile<String>(
                        value: 'sms',
                        groupValue: _method,
                        onChanged: (value) => setState(() => _method = value!),
                        title: const Text(
                          'SMS',
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: const Text(
                          'Receive codes via SMS',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        activeColor: AppTheme.primaryPurple,
                      ),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Authenticator App',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _twoFAEnabled = !_twoFAEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _twoFAEnabled
                        ? '2FA has been disabled'
                        : '2FA has been enabled',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor:
                  _twoFAEnabled ? AppTheme.dangerRed : AppTheme.primaryPurple,
            ),
            child: Text(_twoFAEnabled ? 'Disable 2FA' : 'Enable 2FA'),
          ),
        ],
      ),
    );
  }
}
