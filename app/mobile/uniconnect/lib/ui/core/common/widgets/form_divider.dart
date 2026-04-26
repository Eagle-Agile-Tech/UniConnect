import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/assets.dart';
import '../../../../routing/routes.dart';
import '../../../auth/auth_state_provider.dart';
import '../../theme/dimens.dart';

class SignInWith extends ConsumerWidget {
  const SignInWith({
    super.key,
    this.onPressed,
  });
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authNotifierProvider.notifier);
    return ElevatedButton(
      onPressed: () async {
        final result = await authService.signInWithGoogle();
        result.fold((data) {
          if(data == 'Proceed'){
            context.go(Routes.verifyIdentity);
          } else {
            context.go(Routes.home);
          }
        },
          (error, stackTrace) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: Dimens.iconMd,
            height: Dimens.iconMd,
            child: Image.asset(Assets.googleLogo)
          ),
          SizedBox(width: Dimens.defaultSpace),
          Text('Sign in with Google'),
        ],
      ),
    );
  }
}
