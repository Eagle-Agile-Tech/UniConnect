import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/widets/otp_form.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UCAppBar('Verify Email',),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              Text(
                'Verify Your Identity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              // Instead of the divider, Implement animation
              Divider(
                thickness: 1,
                color: Theme.of(context).primaryColor,
                indent: 100,
                endIndent: 100,
              ),
              SizedBox(height: Dimens.spaceBtwItems),
              Text('We have sent an email with with your code to:'),
              Text('example@example.com'),
              SizedBox(height: Dimens.spaceBtwSections),
              OtpForm(),
              SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () => context.go(Routes.onboardingAcademic),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text('Verify'),
              ),
              SizedBox(height: Dimens.spaceBtwItems),
              Text.rich(
                TextSpan(
                  text: 'Didn\'t receive the code?',
                  children: [
                    TextSpan(
                      text: ' Resend',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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
