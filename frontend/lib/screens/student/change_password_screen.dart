import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../api/auth_api.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String registrationNumber;

  const ChangePasswordScreen({super.key, required this.registrationNumber});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onChangePasswordPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    try {
      await AuthApi.changeStudentPassword(
        registrationNumber: widget.registrationNumber,
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      // You can inspect result if backend returns something extra
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully. Please log in again.'),
        ),
      );

      // After password change, go back to login screen
      Navigator.pop(context, true); // ✅ send success back to login
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final msg = e.toString().replaceFirst('Exception: ', '');
        _errorText = msg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    // backgroundColor: const Color(0xFF6200EE), // Bold purple
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      title: Text(
        'CHANGE PASSWORD',
        style: GoogleFonts.lexend(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(height: 3, color: Colors.black),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(8, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'UPDATE PASSWORD',
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),

                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  isVisible: _showCurrentPassword,
                  onToggle: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  isVisible: _showNewPassword,
                  onToggle: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  isVisible: _showConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value.trim() !=
                        _newPasswordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorText!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                      ),
                    ),
                  ),

                ElevatedButton(
                  onPressed:
                      _isSubmitting ? null : _onChangePasswordPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 20),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Change Password',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

Widget _buildPasswordField({
  required TextEditingController controller,
  required String label,
  required bool isVisible,
  required VoidCallback onToggle,
  required String? Function(String?) validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: !isVisible,
    validator: validator,
    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6200EE), width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.black,
        ),
        onPressed: onToggle,
      ),
    ),
  );
}

