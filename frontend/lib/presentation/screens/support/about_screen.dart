import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    size: 50,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bunga Trader',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Bunga Trader',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Bunga Trader is a professional trading signals platform that helps traders make informed decisions in forex and commodities markets. Our advanced algorithms analyze market trends and provide accurate trading signals.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.6,
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
                  'Features',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem('Real-time Trading Signals'),
                const SizedBox(height: 8),
                _buildFeatureItem('Multi-account Support'),
                const SizedBox(height: 8),
                _buildFeatureItem('Advanced Risk Management'),
                const SizedBox(height: 8),
                _buildFeatureItem('Performance Analytics'),
                const SizedBox(height: 8),
                _buildFeatureItem('24/7 Customer Support'),
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
                  'Legal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLegalLink('Terms of Service'),
                const SizedBox(height: 8),
                _buildLegalLink('Privacy Policy'),
                const SizedBox(height: 8),
                _buildLegalLink('Risk Disclosure'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          color: AppTheme.primaryPurple,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          feature,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLink(String title) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryPurple,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
