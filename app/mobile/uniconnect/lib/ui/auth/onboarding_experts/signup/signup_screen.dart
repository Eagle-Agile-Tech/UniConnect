import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/auth/onboarding/view_models/onboarding_viewmodel_provider.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/common/widgets/signin_with_button.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/enums.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../../../config/dummy_data.dart';
import '../../../../routing/routes.dart';
import '../../../core/common/widgets/form_divider.dart';

class ExpertSignupScreen extends ConsumerStatefulWidget {
  const ExpertSignupScreen({super.key});

  @override
  ConsumerState<ExpertSignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<ExpertSignupScreen> {
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController(text: 'Feysel');
  final _lastNameController = TextEditingController(text: 'Feysel');
  final _emailController = TextEditingController(
    text: 'feysleteshome05@gmail.com',
  );
  final _passwordController = TextEditingController(text: '!@Fffds1ff');
  final _confirmPasswordController = TextEditingController(text: '!@Fffds1ff');
  final _universityCode = TextEditingController(text: '66242');
  final _universityController = TextEditingController(text: '');

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.read(onboardingProvider.notifier);
    return Scaffold(
      appBar: UCAppBar('Expert Onboarding'),
      body: Form(
        key: _signupFormKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: UCSpacingStyle.paddingWithAppBarHeight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: TextFormField(
                        controller: _firstNameController,
                        validator: (value) =>
                            UCValidator.validateEmptyText('First Name', value),
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimens.spaceBtwItems),
                    Flexible(
                      child: TextFormField(
                        controller: _lastNameController,
                        validator: (value) =>
                            UCValidator.validateEmptyText('Last Name', value),
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    final emailStatus = UCValidator.validateEmail(value);
                    switch (emailStatus) {
                      case EmailType.invalid:
                        return 'Please enter a valid email address.';
                      case EmailType.general:
                        return null;
                      case EmailType.institutional:
                        return null;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText:
                        'Use your institutional email for better experience',
                  ),
                ),
                SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _passwordController,
                  validator: (value) => UCValidator.validatePassword(value),
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: (value) => UCValidator.validateConfirmPassword(
                    value,
                    _passwordController.text.trim(),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                ),
                SizedBox(height: Dimens.defaultSpace),
                DropdownMenuFormField(
                  controller: _universityController,
                  validator: (value) => UCValidator.validateEmptyText(
                    'University',
                    value?.acronomy,
                  ),
                  menuStyle: MenuStyle(
                    minimumSize: WidgetStateProperty.all(
                      Size(MediaQuery.of(context).size.width - 32, 0),
                    ),
                  ),
                  enableFilter: true,
                  requestFocusOnTap: true,
                  enableSearch: true,
                  label: const Text('University'),
                  dropdownMenuEntries: UCDummyData.universityEntries,
                ),
                SizedBox(height: Dimens.defaultSpace),
                TextFormField(
                  controller: _universityCode,
                  validator: (value) =>
                      UCValidator.validateUniCode(_universityCode.text.trim()),
                  decoration: const InputDecoration(
                    labelText: 'University Code',
                  ),
                ),
                SizedBox(height: Dimens.spaceBtwSections),
                ElevatedButton(
                  onPressed: () async {
                    if (!_signupFormKey.currentState!.validate()) return;
                    // onboarding.updateAccount(
                    //   _firstNameController.text.trim(),
                    //   _lastNameController.text.trim(),
                    //   _emailController.text.trim(),
                    //   _passwordController.text.trim(),
                    // );
                    final status = await onboarding.submitAccount(
                        _firstNameController.text.trim(),
                          _lastNameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                      _confirmPasswordController.text.trim()
                    );
                    // Todo: make this navigation more robust by listening to the state changes
                    if (status != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(status.toString())),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Account created successfully! Please verify your email.',
                          ),
                        ),
                      );
                      context.go(Routes.verifyEmail);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text('Submit'),
                ),
                SizedBox(height: Dimens.spaceBtwSections),
                FormDivider(),
                SizedBox(height: Dimens.defaultSpace),
                SignInWith(),
                SizedBox(height: Dimens.spaceBtwSections),
                Text.rich(
                  TextSpan(
                    text: "Already have an account?",
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: ' Sign in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.go(Routes.signin);
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
