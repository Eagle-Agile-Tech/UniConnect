import 'package:flutter/material.dart';

import '../../core/common/styles/spacing_style.dart';
import '../../core/common/widgets/form_divider.dart';
import '../../core/common/widgets/signin_with_button.dart';
import '../../core/theme/dimens.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: UCSpacingStyle.paddingWithAppBarHeight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: Dimens.defaultSpace),
            TextFormField(decoration: InputDecoration(labelText: 'Password')),
            SizedBox(height: Dimens.defaultSpace),
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                child: Text('Forgot Password?'),
                onPressed: () {},
              ),
            ),
            SizedBox(height: Dimens.defaultSpace),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Log in'),
            ),
            SizedBox(height: Dimens.spaceBtwSections),

            FormDivider(),
            SizedBox(height: Dimens.defaultSpace),
            SignInWith(),
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
                    recognizer: null,
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
