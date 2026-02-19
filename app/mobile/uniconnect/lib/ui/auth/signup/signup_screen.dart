import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/signin_with_button.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../routing/routes.dart';
import '../../core/common/widgets/form_divider.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
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
                      decoration: const InputDecoration(labelText: 'First Name'),
                    ),
                  ),
                  const SizedBox(width: Dimens.spaceBtwItems),
                  Flexible(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: Dimens.defaultSpace),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: Dimens.defaultSpace),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  SizedBox(width: Dimens.spaceBtwItems),
                  Flexible(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Confirm'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () => context.push(Routes.verifyEmail),
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
                      recognizer: null,
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
