import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/widets/otp_form.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../view_models/onboarding_viewmodel_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreen();
}
class _VerifyEmailScreen extends ConsumerState<VerifyEmailScreen>{
  var otp = '';
  @override
  Widget build(BuildContext context) {
    final onboard = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: UCAppBar('Verify Email', showBack: true, centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: UCSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Divider(
                thickness: 1,
                color: Theme.of(context).primaryColor,
                indent: 100,
                endIndent: 100,
              ),
              SizedBox(height: Dimens.spaceBtwItems),
              Text('We have sent an email with with your code to:'),
              Text(onboard.email),
              SizedBox(height: Dimens.spaceBtwSections),
              OtpForm(
                onOtpChanged: (otpEntered) {
                  otp = otpEntered;
                },
              ),
              SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () async {
                  if(otp.length < 4) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Invalid Otp.')));
                    return;
                  }
                  final status = await ref
                      .read(onboardingProvider.notifier)
                      .verifyOtp(otp);
                  if (status != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(status.toString())));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Email Verified.')));
                    final updatedState = ref.read(onboardingProvider);
                    if (updatedState.university.toLowerCase() == 'General'.toLowerCase()) {
                      context.go(Routes.verifyIdentity);
                    } else {
                      context.go(Routes.onboardingAcademic);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  side: BorderSide(color: onboard.isLoading ? Colors.grey : Theme.of(context).primaryColor)
                ),
                child: onboard.isLoading ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  )
                ) : Text('Verify'),
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
