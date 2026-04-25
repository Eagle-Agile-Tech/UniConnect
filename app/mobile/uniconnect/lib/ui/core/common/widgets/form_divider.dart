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
    this.isGoogle = true,
    this.onPressed,
  });
  final bool isGoogle;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authNotifierProvider.notifier);
    return ElevatedButton(
      onPressed: isGoogle ? () async {
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
      } : () async {
        final result = await authService.signInWithMicrosoft();
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
            child: isGoogle ? Image.asset(Assets.googleLogo) : SvgPicture.asset(Assets.microsoftLogo),
          ),
          SizedBox(width: Dimens.defaultSpace),
          Text(isGoogle ? 'Sign in with Google' : 'Sign in with Microsoft'),
        ],
      ),
    );
  }
}
