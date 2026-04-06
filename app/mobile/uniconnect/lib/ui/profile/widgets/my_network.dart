import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../routing/routes.dart';
import '../../../utils/helper_functions.dart';
import '../../core/theme/dimens.dart';
import '../view_models/user_provider.dart';

class MyNetwork extends ConsumerWidget {
  const MyNetwork({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.value!.user;
    return Container(
      width: 200,
      padding: EdgeInsets.all(Dimens.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            UCHelperFunctions.formatMembers(50500),
            style: TextStyle(
              fontSize: Dimens.fontMd,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: Dimens.spaceBtwItems),
          InkWell(
            onTap: () {
              ref.read(selectedUserProfileProvider.notifier).state =
                  currentUser;
              context.push(Routes.networks);
            },
            child: Text(
              'Network',
              style: TextStyle(
                fontSize: Dimens.fontMd,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
