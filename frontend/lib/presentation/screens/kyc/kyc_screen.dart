import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('KYC Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          const SizedBox(height: 32),

          // Step Content
          _buildStepContent(),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('KYC submission started')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.primaryPurple,
                  ),
                  child: Text(_currentStep == 2 ? 'Submit' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) {
            return Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppTheme.primaryPurple
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= _currentStep
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  const ['Personal', 'Documents', 'Address'][index],
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfo();
      case 1:
        return _buildDocuments();
      case 2:
        return _buildAddress();
      default:
        return Container();
    }
  }

  Widget _buildPersonalInfo() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildField('First Name'),
          const SizedBox(height: 12),
          _buildField('Last Name'),
          const SizedBox(height: 12),
          _buildField('Date of Birth'),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildUploadBox('ID Document (Passport/Driver License)'),
          const SizedBox(height: 12),
          _buildUploadBox('Proof of Address'),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Address Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildField('Country'),
          const SizedBox(height: 12),
          _buildField('City'),
          const SizedBox(height: 12),
          _buildField('Address'),
          const SizedBox(height: 12),
          _buildField('Postal Code'),
        ],
      ),
    );
  }

  Widget _buildField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter $label',
            filled: true,
            fillColor: AppTheme.darkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.textSecondary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary, width: 1.5),
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.darkBackground,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 32, color: AppTheme.textSecondary),
                SizedBox(height: 8),
                Text(
                  'Tap to upload',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
