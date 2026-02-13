import 'package:flutter/material.dart';

import '../../../../config/assets.dart';
import '../../theme/dimens.dart';

class SignInWith extends StatelessWidget {
  const SignInWith({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: null,
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
    );
  }
}
