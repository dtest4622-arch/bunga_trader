import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../profile/profile_screen.dart';
import '../kyc/kyc_screen.dart';
import '../trading_settings/risk_settings_screen.dart';
import '../trading_settings/compounding_screen.dart';
import '../trading_settings/signal_preferences_screen.dart';
import '../support/help_center_screen.dart';
import '../support/contact_support_screen.dart';
import '../support/about_screen.dart';
import 'change_password_screen.dart';
import 'two_fa_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Manage your personal information',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'KYC Verification',
              subtitle: 'Complete your identity verification',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KYCScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Trading Section
          _buildSectionHeader('Trading'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.trending_up,
              title: 'Risk Settings',
              subtitle: 'Configure risk management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiskSettingsScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.account_tree_outlined,
              title: 'Compounding',
              subtitle: 'Set up automatic compounding',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompoundingScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.notifications_active_outlined,
              title: 'Signal Preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignalPreferencesScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive trade and signal alerts',
              value: true,
              onChanged: (value) {
                // Toggle notifications
              },
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive email updates',
              value: false,
              onChanged: (value) {
                // Toggle email notifications
              },
            ),
            _buildSwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Sound Alerts',
              value: true,
              onChanged: (value) {
                // Toggle sound
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader('Security'),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face ID',
              value: true,
              onChanged: (value) {
                // Toggle biometric
              },
            ),
            _buildSettingsTile(
              icon: Icons.security_outlined,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TwoFAScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.chat_bubble_outline,
              title: 'Contact Support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen()),
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Version ${AppConstants.appVersion}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              _showLogoutDialog(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.primaryPurple,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
