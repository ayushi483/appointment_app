import 'package:flutter/material.dart';
import 'package:clinic_management/app/modules/registration/controllers/registration_controllers.dart';
import '../../../routes/app_routes.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  final _controller = RegistrationController();

  // Gender options
  static const _genderOptions = [
    {'label': 'Male', 'value': 'male', 'icon': Icons.male},
    {'label': 'Female', 'value': 'female', 'icon': Icons.female},
    {'label': 'Other', 'value': 'other', 'icon': Icons.transgender},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _controller.isLoading = true);
    final result = await _controller.register();
    if (mounted) setState(() => _controller.isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
        arguments: {'name': result['name']},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Gender bottom sheet ────────────────────────────────────────────────────
  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Gender',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._genderOptions.map((option) {
                  final isSelected =
                      _controller.selectedGender == option['value'];
                  return ListTile(
                    leading: Icon(
                      option['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : Colors.grey,
                    ),
                    title: Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                        color: Color(0xFF2563EB))
                        : null,
                    onTap: () {
                      _controller.setGender(
                          option['value'] as String, setState);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenderLabel = _genderOptions.firstWhere(
          (o) => o['value'] == _controller.selectedGender,
      orElse: () => {'label': 'Select gender'},
    )['label'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sliver blue header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF2563EB),
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sign up to get started',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full Name
                _label('Full Name'),
                _textField(
                  controller: _controller.nameController,
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                // Email
                _label('Email Address'),
                _textField(
                  controller: _controller.emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Phone
                _label('Phone Number'),
                _textField(
                  controller: _controller.phoneController,
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Gender — tappable field that opens bottom sheet
                _label('Gender'),
                GestureDetector(
                  onTap: _showGenderPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _controller.selectedGender == null
                              ? Icons.wc_outlined
                              : (_genderOptions.firstWhere(
                                  (o) =>
                              o['value'] ==
                                  _controller.selectedGender,
                              orElse: () =>
                              {'icon': Icons.wc_outlined})
                          ['icon'] as IconData),
                          color: _controller.selectedGender == null
                              ? Colors.grey
                              : const Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _controller.selectedGender == null
                                ? 'Select gender'
                                : selectedGenderLabel,
                            style: TextStyle(
                              fontSize: 16,
                              color: _controller.selectedGender == null
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                _label('Password'),
                _passwordField(
                  controller: _controller.passwordController,
                  hint: 'Create a password',
                  obscure: _controller.obscurePassword,
                  onToggle: () =>
                      _controller.togglePasswordVisibility(setState),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _label('Confirm Password'),
                _passwordField(
                  controller: _controller.confirmPasswordController,
                  hint: 'Confirm your password',
                  obscure: _controller.obscureConfirm,
                  onToggle: () =>
                      _controller.toggleConfirmVisibility(setState),
                ),
                const SizedBox(height: 16),

                // Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _controller.agreedToTerms,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (v) =>
                          _controller.toggleTerms(v, setState),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Create Account button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                    _controller.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _controller.isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14)),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
        const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }
}