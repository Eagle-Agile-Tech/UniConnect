import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/widets/otp_form.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../view_models/onboarding_viewmodel.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var otp = '';
    final onboardingState = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: UCAppBar('Verify Email', showBack: false, centerTitle: true),
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
              Text(onboardingState.email),
              SizedBox(height: Dimens.spaceBtwSections),
              OtpForm(onOtpChanged: (otpEntered){
                otp = otpEntered;
              },),
              SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () {
                  final status = ref.read(onboardingProvider.notifier).verifyOtp(otp);
                  if (status != null){
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(status.toString()))
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email Verified.'))
                    );
                    context.go(Routes.onboardingAcademic);
                  }
                },
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
