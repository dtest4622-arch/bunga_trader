import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqItems = [
      {
        'question': 'How do I create a trading account?',
        'answer':
            'Go to Accounts tab and click Add Account. Follow the setup wizard to connect your MT5 account.',
      },
      {
        'question': 'What is the minimum deposit?',
        'answer':
            'The minimum deposit depends on your broker. Typically it ranges from \$100 to \$1000.',
      },
      {
        'question': 'How accurate are the trading signals?',
        'answer':
            'Our signals have a historical accuracy of 65-75%. Results may vary based on market conditions.',
      },
      {
        'question': 'Can I withdraw my earnings?',
        'answer':
            'Yes, you can withdraw your earnings anytime. Withdrawals are processed within 2-5 business days.',
      },
      {
        'question': 'What is compounding?',
        'answer':
            'Compounding reinvests your profits into new trades, allowing exponential growth of your account.',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Search help articles...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FAQ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: faqItems.length,
            itemBuilder: (context, index) {
              return _buildFAQItem(faqItems[index] as Map<String, dynamic>);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          item['question'] as String,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Text(
              item['answer'] as String,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
