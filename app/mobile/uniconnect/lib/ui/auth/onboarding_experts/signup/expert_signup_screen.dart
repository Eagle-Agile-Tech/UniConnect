import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/utils/enums.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../../../config/dummy_data.dart';
import '../../../../routing/routes.dart';
import '../../../core/common/widgets/form_divider.dart';
import '../../../core/common/widgets/signin_with_button.dart';
import '../viewmodel/expert_onboarding_provider.dart';

class ExpertSignupScreen extends ConsumerStatefulWidget {
  const ExpertSignupScreen({super.key});

  @override
  ConsumerState<ExpertSignupScreen> createState() => _SignupScreenState();
}


class _SignupScreenState extends ConsumerState<ExpertSignupScreen> {
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _universityCode;
  late final TextEditingController _universityController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: 'Feysel');
    _lastNameController = TextEditingController(text: 'Feysel');
    _emailController = TextEditingController(text: 'feysleteshome05@gmail.com');
    _passwordController = TextEditingController(text: '!@Fffds1ff');
    _confirmPasswordController = TextEditingController(text: '!@Fffds1ff');
    _universityCode = TextEditingController(text: '66242');
    _universityController = TextEditingController();
  }

  @override
  void dispose() {
    for (var controller in [
      _firstNameController, _lastNameController, _emailController,
      _passwordController, _confirmPasswordController, _universityCode, _universityController
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onboarding = ref.read(expertOnboardingProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _signupFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(onPressed: context.pop, icon: Icon(Icons.arrow_back)),
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
                  Text(
                    "Create your expert profile to start mentoring students and sharing your wisdom.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (v) => UCValidator.validateEmptyText('First Name', v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (v) => UCValidator.validateEmptyText('Last Name', v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Institutional Email',
                    icon: Icons.email_outlined,
                    hint: 'name@university.edu',
                    validator: (v) {
                      final status = UCValidator.validateEmail(v);
                      return (status == EmailType.invalid) ? 'Enter a valid email' : null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (v) => UCValidator.validatePassword(v),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_reset_outlined,
                    isPassword: true,
                    validator: (v) => UCValidator.validateConfirmPassword(v, _passwordController.text),
                  ),
                  const SizedBox(height: 24),

                  const Divider(),
                  const SizedBox(height: 16),

                  DropdownMenuFormField(
                    controller: _universityController,
                    label: const Text('Select University'),
                    dropdownMenuEntries: UCDummyData.universityEntries,
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) => UCValidator.validateEmptyText(
                      'University',
                      _universityController.text.trim(),
                    ),
                    width: MediaQuery.of(context).size.width - 48,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _universityCode,
                    label: 'University Verification Code',
                    icon: Icons.verified_user_outlined,
                    validator: (v) => UCValidator.validateUniCode(v),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleSignup(onboarding),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Expert Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const FormDivider(),
                  const SizedBox(height: 24),
                  const SignInWith(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Future<void> _handleSignup(ExpertOnboardingViewModel onboarding) async {
    if (!_signupFormKey.currentState!.validate()) return;

    final status = await onboarding.registerExpert(
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _emailController.text.trim(),
      _universityController.text.trim(),
      _universityCode.text.trim(),
      _passwordController.text.trim(),
      _confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (status != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status.toString())));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully. Verify Your Email.')),
      );
      context.push(Routes.expertVerifyUni);
    }
  }
}
