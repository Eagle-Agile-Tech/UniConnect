import 'package:flutter/material.dart';
import 'package:uniconnect/ui/auth/onboarding/widets/otp_form.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Email'),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton.outlined(
          onPressed: null,
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).primaryColor.withValues(alpha: 0.8),),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(width: 1.5, color: Theme.of(context).primaryColor),
          ),
        ),
      ),
      body: Padding(
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
              onPressed: () {},
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
    );
  }
}
