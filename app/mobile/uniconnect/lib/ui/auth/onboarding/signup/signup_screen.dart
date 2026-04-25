import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/auth/onboarding/view_models/onboarding_viewmodel_provider.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/signin_with_button.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/enums.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../../../routing/routes.dart';
import '../../../core/common/widgets/form_divider.dart';
import '../../auth_state_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController(text: 'Feysel');
  final _lastNameController = TextEditingController(text: 'Teshome');
  final _emailController = TextEditingController(
    text: 'feyteshome@ju2.edu.et',
  );
  final _passwordController = TextEditingController(text: '!@Fffds1ff');
  final _confirmPasswordController = TextEditingController(text: '!@Fffds1ff');
  bool _isPassVisible = true;
  bool _isPassConfirmVisible = true;

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
    final onboard = ref.watch(onboardingProvider);
    return Form(
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
                      decoration: const InputDecoration(labelText: 'Last Name'),
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
                obscureText: _isPassVisible,
                decoration: InputDecoration(labelText: 'Password',suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPassVisible = !_isPassVisible;
                    });
                  },
                  icon: Icon(_isPassVisible ? Icons.visibility : Icons.visibility_off),
                )),
              ),
              SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                controller: _confirmPasswordController,
                validator: (value) => UCValidator.validateConfirmPassword(
                  value,
                  _passwordController.text.trim(),
                ),
                obscureText: _isPassConfirmVisible,
                decoration: InputDecoration(labelText: 'Confirm Password',suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _isPassConfirmVisible = !_isPassConfirmVisible;
                    });
                  },
                  icon: Icon(_isPassConfirmVisible ? Icons.visibility : Icons.visibility_off),
                )),
              ),
              SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: onboard.isLoading ? null : () async {
                  if (!_signupFormKey.currentState!.validate()) return;
                  final status = await onboarding.submitAccount(
                    _confirmPasswordController.text.trim(),
                    _firstNameController.text.trim(),
                    _lastNameController.text.trim(),
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  if (status != null){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(status.toString()))
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account created successfully! Please verify your email.'))
                    );
                    context.push(Routes.verifyEmail);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  side: BorderSide(color: onboard.isLoading ? Colors.grey : Theme.of(context).primaryColor),
                ),
                child: onboard.isLoading ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ) : Text('Submit'),
              ),
              SizedBox(height: Dimens.spaceBtwSections),
              FormDivider(),
              SizedBox(height: Dimens.defaultSpace),
              SignInWith(
                onPressed: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
              ),
              SizedBox(height: Dimens.spaceBtwItems,),
              SignInWith(isGoogle: false, onPressed: () {}),
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
                          DefaultTabController.of(context).animateTo(0);
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
