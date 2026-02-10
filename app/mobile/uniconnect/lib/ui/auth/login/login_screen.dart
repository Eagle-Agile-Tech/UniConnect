import 'package:flutter/material.dart';

import '../../../config/assets.dart';
import '../../core/theme/dimens.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: Dimens.spaceBtwSections),
        TextField(decoration: InputDecoration(labelText: 'Email')),
        SizedBox(height: Dimens.spaceBtwItems),
        TextField(decoration: InputDecoration(labelText: 'Password')),
        SizedBox(height: Dimens.spaceBtwItems),
        Align(
          alignment: Alignment.topRight,
          child: TextButton(child: Text('Forgot Password?'), onPressed: () {}),
        ),
        SizedBox(height: Dimens.spaceBtwItems),
        ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 48),
          ),
          child: Text('Log in'),
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
        SizedBox(height: Dimens.spaceBtwItems),
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
              SizedBox(width: Dimens.spaceBtwItems),
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
                text: ' Sign up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                recognizer: null,
              ),
            ],
          ),
        )
      ],
    );
  }
}
