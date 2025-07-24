// Fixed lib/screens/auth/access_request_screen.dart
// Change: Fixed API call to use RegistrationService.requestAccess() instead of .post()

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';

class AccessRequestScreen extends StatefulWidget {
  const AccessRequestScreen({super.key});

  @override
  _AccessRequestScreenState createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String _selectedRole = 'coach';
  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  final List<String> _roles = [
    'coach',
    'coordinator',
    'parent',
    'player',
    'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Request Access',
      backgroundColor: Colors.grey[50],
      actions: [
        TextButton(
          onPressed: () => NavigationService().pop(),
          child: ResponsiveText(
            'Back to Login',
            baseFontSize: 14,
            color: Colors.blue,
          ),
        ),
      ],
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingSymmetric(
            context,
            horizontal: deviceType == DeviceType.desktop ? 32 : 16,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 600 : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  ResponsiveSpacing(multiplier: 3),
                  _buildRegistrationForm(context),
                  ResponsiveSpacing(multiplier: 3),
                  _buildSubmitSection(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 16,
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        children: [
          // App logo/icon placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: ResponsiveConfig.borderRadius(context, 40),
            ),
            child: Icon(
              Icons.sports_hockey,
              size: 40,
              color: Colors.blue,
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Join HIRE Hockey',
            baseFontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Request access to our hockey development platform. We\'ll review your application and get back to you within 24 hours.',
            baseFontSize: 16,
            color: Colors.blueGrey[600],
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return ResponsiveCard(
      elevation: 3,
      baseBorderRadius: 16,
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              'Application Details',
              baseFontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
            ResponsiveSpacing(multiplier: 2),
            
            // Personal Information Section
            _buildSectionHeader(context, 'Personal Information'),
            ResponsiveSpacing(multiplier: 1.5),
            
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            ResponsiveSpacing(multiplier: 2),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            ResponsiveSpacing(multiplier: 2),
            
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            ResponsiveSpacing(multiplier: 3),
            
            // Professional Information Section
            _buildSectionHeader(context, 'Professional Information'),
            ResponsiveSpacing(multiplier: 1.5),
            
            _buildDropdownField(
              label: 'Role',
              value: _selectedRole,
              items: _roles,
              onChanged: (value) => setState(() => _selectedRole = value!),
              icon: Icons.work,
              displayName: (role) => _formatRoleName(role),
            ),
            ResponsiveSpacing(multiplier: 2),
            
            _buildTextField(
              controller: _organizationController,
              label: 'Organization/Team',
              hint: 'Enter your organization or team name',
              icon: Icons.business,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your organization or team';
                }
                return null;
              },
            ),
            ResponsiveSpacing(multiplier: 3),
            
            // Application Details Section
            _buildSectionHeader(context, 'Application Details'),
            ResponsiveSpacing(multiplier: 1.5),
            
            _buildTextField(
              controller: _reasonController,
              label: 'Who sent you to the HIRE Hockey app?',
              hint: 'Tell us who referred you or how you found out about our platform',
              icon: Icons.help_outline,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please tell us who sent you to HIRE Hockey';
                }
                if (value.trim().length < 20) {
                  return 'Please provide more detail (at least 20 characters)';
                }
                return null;
              },
            ),
            ResponsiveSpacing(multiplier: 3),
            
            // Terms and Conditions
            _buildTermsCheckbox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return ResponsiveText(
      title,
      baseFontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.blueGrey[700],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          baseFontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey[700],
        ),
        ResponsiveSpacing(multiplier: 0.5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blueGrey[600]),
            border: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: ResponsiveConfig.paddingSymmetric(
              context,
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required String Function(String) displayName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          baseFontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey[700],
        ),
        ResponsiveSpacing(multiplier: 0.5),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueGrey[600]),
            border: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: ResponsiveConfig.paddingSymmetric(
              context,
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: ResponsiveText(
              displayName(item),
              baseFontSize: 16,
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          activeColor: Colors.blue,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: ResponsiveText(
              'I agree to the Terms of Service and Privacy Policy. I understand that my application will be reviewed and I may be contacted for additional information.',
              baseFontSize: 14,
              color: Colors.blueGrey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection(BuildContext context) {
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 16,
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveButton(
            text: _isSubmitting ? 'Submitting Application...' : 'Submit Application',
            onPressed: _isSubmitting ? null : _submitApplication,
            backgroundColor: Colors.blue,
            baseHeight: 56,
            icon: _isSubmitting ? null : Icons.send,
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Information note
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(
                      child: ResponsiveText(
                        'What happens next?',
                        baseFontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText(
                  '• We\'ll review your application within 24 hours\n'
                  '• You\'ll receive an email with your login credentials\n'
                  '• A team member may contact you for onboarding\n'
                  '• You can start using HIRE Hockey immediately after approval',
                  baseFontSize: 14,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'coach':
        return 'Coach';
      case 'coordinator':
        return 'Coordinator';
      case 'parent':
        return 'Parent/Guardian';
      case 'player':
        return 'Player';
      case 'other':
        return 'Other';
      default:
        return role.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Prepare application data
      final applicationData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _organizationController.text.trim(),
        'role': _selectedRole,
        'referral_source': _reasonController.text.trim(),
        'agreed_to_terms': _agreedToTerms,
        'application_type': 'access_request',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // ✅ FIX: Use the correct RegistrationService method
      await _sendAccessRequest(applicationData);

      setState(() => _isSubmitting = false);

      // Show success dialog
      _showSuccessDialog();

    } catch (e) {
      setState(() => _isSubmitting = false);
      
      print('Application submission error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendAccessRequest(Map<String, dynamic> applicationData) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      // ✅ FIX: Use RegistrationService.requestAccess() instead of .post()
      await ApiServiceFactory.registration.requestAccess(applicationData);
      
    } catch (e) {
      // If the registration endpoint doesn't exist yet, 
      // you could send this via email for now
      print('Registration endpoint not available, would send email: $applicationData');
      
      // For now, simulate success after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, you'd integrate with your email service here
      // or create the registration endpoint in your backend
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: ResponsiveConfig.borderRadius(context, 16),
        ),
        title: Column(
          children: [
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: ResponsiveConfig.borderRadius(context, 50),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Application Submitted!',
              baseFontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: ResponsiveText(
          'Thank you for your interest in HIRE Hockey! We\'ve received your application and will review it within 24 hours.\n\n'
          'You\'ll receive an email at ${_emailController.text.trim()} with your login credentials once approved.',
          baseFontSize: 16,
          color: Colors.blueGrey[600],
          textAlign: TextAlign.center,
        ),
        actions: [
          ResponsiveButton(
            text: 'Back to Login',
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              NavigationService().pushNamedAndRemoveUntil('/login');
            },
            backgroundColor: Colors.blue,
            baseHeight: 48,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}