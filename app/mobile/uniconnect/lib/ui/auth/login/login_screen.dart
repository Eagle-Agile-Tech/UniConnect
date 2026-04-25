import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/utils/validator.dart';

import '../../../routing/routes.dart';
import '../../core/common/styles/spacing_style.dart';
import '../../core/common/widgets/form_divider.dart';
import '../../core/common/widgets/signin_with_button.dart';
import '../../core/theme/dimens.dart';
import '../auth_state_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'feyteshome@ju2.edu.et');
  final _password = TextEditingController(text: '!@Fffds1ff');
  bool _isPassVisible = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider.notifier);
    return Padding(
      padding: UCSpacingStyle.paddingWithAppBarHeight,
      child: SingleChildScrollView(
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                validator: (value) =>
                    UCValidator.validateEmptyText('username', value),
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                controller: _password,
                validator: (value) =>
                    UCValidator.validateEmptyText('password', value),
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
              SizedBox(height: Dimens.sm),
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  child: Text('Forgot Password?'),
                  onPressed: () {
                    if(_email.text.trim().isEmpty){
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter your email')));
                      return;
                    }
                    auth.sendOtp(_email.text.trim());
                    context.push(Routes.forgetEmailPath, extra: _email.text.trim());
                  },
                ),
              ),
              SizedBox(height: Dimens.defaultSpace),
              ElevatedButton(
                onPressed: () async {
                  if (!_key.currentState!.validate()) return;
                  await auth.login(
                    _email.text.trim(),
                    _password.text.trim(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Log in'),
              ),
              SizedBox(height: Dimens.spaceBtwSections),

              FormDivider(),
              SizedBox(height: Dimens.defaultSpace),
              SignInWith(),
              SizedBox(height: Dimens.spaceBtwItems),
              SignInWith(isGoogle: false),
              SizedBox(height: Dimens.spaceBtwSections),
              Text.rich(
                TextSpan(
                  text: "Don't have an account?",
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: ' Sign up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    DefaultTabController.of(context).animateTo(1);
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
