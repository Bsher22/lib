import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/utils/validation_helper.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';

class UserFormScreen extends StatefulWidget {
  final String userRole;
  final User? user;
  
  const UserFormScreen({
    Key? key,
    required this.userRole,
    this.user,
  }) : super(key: key);

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  bool _formSubmitted = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _formSubmitted = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Prepare user data
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'role': widget.userRole,
      };
      
      // Add password only if provided or for new users
      final password = _passwordController.text;
      if (password.isNotEmpty || widget.user == null) {
        userData['password'] = password;
      }
      
      bool success = false;
      
      if (widget.user != null) {
        // Update existing user
        if (widget.user!.id != null) {
          final updatedUser = await appState.api.updateUser(widget.user!.id!, userData);
          success = updatedUser != null;
        }
      } else {
        // Create new user
        final newUser = await appState.api.registerUser(userData);
        success = newUser != null;
      }
      
      if (success) {
        // Reload users data
        if (widget.userRole == 'coach') {
          await appState.api.fetchUsersByRole('coach');
        } else if (widget.userRole == 'coordinator') {
          await appState.api.fetchUsersByRole('coordinator');
        }
        
        if (!mounted) return;
        
        // Return to previous screen with success indicator
        Navigator.pop(context, true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              widget.user != null 
                ? '${widget.userRole.capitalize()} updated successfully' 
                : '${widget.userRole.capitalize()} created successfully',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.user != null 
            ? 'Failed to update ${widget.userRole}' 
            : 'Failed to create ${widget.userRole}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final roleDisplay = widget.userRole.capitalize();
    final roleColor = widget.userRole == 'coach' ? Colors.green : Colors.blue;
    
    return AdaptiveScaffold(
      title: isEdit ? 'Edit $roleDisplay' : 'Add $roleDisplay',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: ResponsiveConfig.dimension(context, 32),
                        height: ResponsiveConfig.dimension(context, 32),
                        child: const CircularProgressIndicator(color: Colors.cyanAccent),
                      ),
                      ResponsiveSpacing(multiplier: 2),
                      ResponsiveText('Saving user...', baseFontSize: 16),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: ResponsiveConfig.paddingAll(context, 16),
                          child: ConstrainedBox(
                            constraints: ResponsiveConfig.constraints(
                              context,
                              maxWidth: deviceType == DeviceType.desktop ? 600 : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRoleBadgeSection(roleDisplay, roleColor),
                                ResponsiveSpacing(multiplier: 3),
                                _buildUserDetailsSection(deviceType, isEdit, roleColor),
                                
                                // Error message
                                if (_errorMessage != null && _formSubmitted) ...[
                                  ResponsiveSpacing(multiplier: 2),
                                  ResponsiveText(
                                    _errorMessage!,
                                    baseFontSize: 14,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildActionBar(isEdit, roleDisplay),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildRoleBadgeSection(String roleDisplay, Color roleColor) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Center(
        child: Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: ResponsiveConfig.borderRadius(context, 16),
            border: Border.all(color: roleColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.userRole == 'coach' ? Icons.sports : Icons.people_alt,
                size: ResponsiveConfig.iconSize(context, 18),
                color: roleColor,
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                roleDisplay,
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: roleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailsSection(DeviceType deviceType, bool isEdit, Color roleColor) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline, 
                color: Colors.blueGrey[600], 
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'User Information',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Name field
          StandardTextField(
            controller: _nameController,
            labelText: 'Full Name *',
            prefixIcon: Icons.person,
            validator: ValidationHelper.required('Please enter a name'),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Email and Username fields - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardTextField(
                      controller: _emailController,
                      labelText: 'Email Address *',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidationHelper.compose([
                        ValidationHelper.required('Please enter an email address'),
                        ValidationHelper.email('Please enter a valid email address'),
                      ]),
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardTextField(
                      controller: _usernameController,
                      labelText: 'Username *',
                      prefixIcon: Icons.account_circle,
                      helperText: isEdit 
                        ? 'Changing username may affect login credentials'
                        : 'Username for login purposes',
                      enabled: !isEdit, // Can't change username for existing users
                      validator: ValidationHelper.compose([
                        ValidationHelper.required('Please enter a username'),
                        ValidationHelper.minLength(4, 'Username must be at least 4 characters'),
                      ]),
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardTextField(
                        controller: _emailController,
                        labelText: 'Email Address *',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidationHelper.compose([
                          ValidationHelper.required('Please enter an email address'),
                          ValidationHelper.email('Please enter a valid email address'),
                        ]),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardTextField(
                        controller: _usernameController,
                        labelText: 'Username *',
                        prefixIcon: Icons.account_circle,
                        helperText: isEdit 
                          ? 'Changing username may affect login credentials'
                          : 'Username for login purposes',
                        enabled: !isEdit, // Can't change username for existing users
                        validator: ValidationHelper.compose([
                          ValidationHelper.required('Please enter a username'),
                          ValidationHelper.minLength(4, 'Username must be at least 4 characters'),
                        ]),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Password field
          StandardTextField(
            controller: _passwordController,
            labelText: isEdit ? 'New Password' : 'Password *',
            prefixIcon: Icons.lock,
            obscureText: !_isPasswordVisible,
            helperText: isEdit 
              ? 'Leave blank to keep current password'
              : 'Must be at least 8 characters with uppercase, digits, and special characters',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: isEdit
              ? (value) => value!.isNotEmpty ? ValidationHelper.password()(value) : null
              : ValidationHelper.password(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isEdit, String roleDisplay) {
    return Container(
      width: double.infinity,
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ResponsiveButton(
          text: isEdit ? 'Save Changes' : 'Create $roleDisplay',
          onPressed: _isLoading ? null : _saveUser,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          isLoading: _isLoading,
          loadingText: isEdit ? 'Updating user...' : 'Creating user...',
        ),
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}