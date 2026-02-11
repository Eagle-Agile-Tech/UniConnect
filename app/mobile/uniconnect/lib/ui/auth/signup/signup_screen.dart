import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../config/assets.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
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
                SizedBox(width: Dimens.spaceBtwItems),
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
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Submit'),
            ),
            SizedBox(height: Dimens.spaceBtwSections),
            Row(
              children: [
                Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Text('Or'),
                ),
                Expanded(child: Divider(thickness: 1, color: Colors.grey)),
              ],
            ),
            SizedBox(height: Dimens.defaultSpace),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: Dimens.iconMd,
                    height: Dimens.iconMd,
                    child: Image.asset(Assets.googleLogo),
                  ),
                  SizedBox(width: Dimens.defaultSpace),
                  Text('Sign in with Google'),
                ],
              ),
            ),
            SizedBox(height: Dimens.spaceBtwSections),
            Text.rich(
              TextSpan(
                text: "Don't have an account?",
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
    );
  }
}
