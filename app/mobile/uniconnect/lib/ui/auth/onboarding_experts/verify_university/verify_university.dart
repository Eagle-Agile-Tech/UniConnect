import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/routes.dart';
import '../../onboarding/verify_email/widets/otp_form.dart';
import '../../onboarding/view_models/onboarding_viewmodel_provider.dart';
import '../../onboarding_experts/viewmodel/expert_onboarding_provider.dart';
import '../../../core/common/styles/spacing_style.dart';
import '../../../core/common/widgets/app_bar.dart';
import '../../../core/theme/dimens.dart';

class ExpertVerifyUni extends ConsumerStatefulWidget {
  const ExpertVerifyUni({super.key});

  @override
  ConsumerState<ExpertVerifyUni> createState() => _ExpertVerifyUniState();
}

class _ExpertVerifyUniState extends ConsumerState<ExpertVerifyUni> {
  var otp = '';

  @override
  Widget build(BuildContext context) {
    final expertOnboarding = ref.watch(expertOnboardingProvider);

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
              const SizedBox(height: Dimens.spaceBtwItems),
              const Text('We\'ve sent a verification code to:'),
              Text(expertOnboarding.email),
              const SizedBox(height: Dimens.spaceBtwSections),
              OtpForm(
                onOtpChanged: (otpEntered) {
                  otp = otpEntered;
                },
              ),
              const SizedBox(height: Dimens.spaceBtwSections),
              ElevatedButton(
                onPressed: () async {
                  if (otp.length < 4) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Invalid OTP.')));
                    return;
                  }

                  final status = await ref
                      .read(expertOnboardingProvider.notifier)
                      .verifyEmail(otp);

                  if (!context.mounted) return;

                  if (status != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(status.toString())));
                    return;
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Email verified.')));
                  context.go(Routes.expertProfile);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Verify'),
              ),
              const SizedBox(height: Dimens.spaceBtwItems),
              SizedBox(height: Dimens.spaceBtwItems),
              Text.rich(
                TextSpan(
                  text: "Didn't receive the code?",
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: ' Resend',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ref.read(onboardingProvider.notifier).sendOtp(expertOnboarding.email);
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
