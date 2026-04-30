import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/widets/otp_form.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/common/widgets/app_bar.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import 'package:uniconnect/utils/helper_functions.dart';
import '../../../../utils/validator.dart';
import '../../onboarding/view_models/onboarding_viewmodel_provider.dart';


class ForgetEmailScreen extends ConsumerStatefulWidget {
  const ForgetEmailScreen({super.key, required this.email});
  final String email;
  @override
  ConsumerState<ForgetEmailScreen> createState() => _VerifyEmailScreen();
}
class _VerifyEmailScreen extends ConsumerState<ForgetEmailScreen>{
  final _passwordController = TextEditingController(text: '!@Fffds1ff');
  final _confirmPasswordController = TextEditingController(text: '!@Fffds1ff');
  bool _isPassVisible = true;
  bool _isPassConfirmVisible = true;
  var otp = '';
  @override
  Widget build(BuildContext context) {
    final onboard = ref.watch(onboardingProvider);
    return Scaffold(
      appBar: UCAppBar('Change Your Password', showBack: true, centerTitle: true),
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
              Text(widget.email),
              SizedBox(height: Dimens.spaceBtwSections),
              OtpForm(
                onOtpChanged: (otpEntered) {
                  otp = otpEntered;
                },
              ),
              SizedBox(height: Dimens.spaceBtwSections),
              TextFormField(
                controller: _passwordController,
                validator: (value) => UCValidator.validatePassword(value),
                obscureText: _isPassVisible,
                decoration: InputDecoration(labelText: 'New Password',suffixIcon: IconButton(
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
                onPressed: () async {
                  if(otp.length < 4) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Invalid Otp.')));
                    return;
                  }
                  final status = await ref
                      .read(onboardingProvider.notifier)
                      .changePassword(widget.email, otp, _passwordController.text.trim(), _confirmPasswordController.text.trim());
                  if (status != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(UCHelperFunctions.getErrorMessage(status))));
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Password changed successfully.')));
                    context.go(Routes.loginOrSignup);
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
                ) : Text('Submit'),
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
