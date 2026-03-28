import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'general';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Contact Support'),
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
                  'Category',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  onChanged: (value) => setState(() => _category = value!),
                  items: const [
                    DropdownMenuItem(
                        value: 'general', child: Text('General Inquiry')),
                    DropdownMenuItem(
                        value: 'technical', child: Text('Technical Issue')),
                    DropdownMenuItem(
                        value: 'account', child: Text('Account Issue')),
                    DropdownMenuItem(
                        value: 'trading', child: Text('Trading Question')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Subject',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Enter subject',
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Message',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue or question...',
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
              if (_subjectController.text.isEmpty ||
                  _messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent to support team')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppTheme.primaryPurple,
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
