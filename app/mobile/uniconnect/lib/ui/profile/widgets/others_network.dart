import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/user/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/helper_functions.dart';
import '../../core/theme/dimens.dart';
import '../view_models/user_provider.dart';

class OthersNetwork extends ConsumerWidget {
  const OthersNetwork({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(user.networkCount > 40)
              Text(
                UCHelperFunctions.formatMembers(user.networkCount),
                style: TextStyle(
                  fontSize: Dimens.fontMd,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: Dimens.xs),
              InkWell(
                onTap: user.areWe ? () {
                  ref.read(selectedUserProfileProvider.notifier).state = user;
                  context.push(Routes.networks);
                } : () {},
                //take him to another screen : make them network,
                child: Text(
                  user.areWe ? 'Linked' : 'Network',
                  style: TextStyle(
                    fontSize: Dimens.fontMd,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Dimens.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push(
              Routes.messaging,
              extra: {'userId': user.id, 'username': user.username},
            ),
            child: Text(
              'Chat',
              style: TextStyle(
                fontSize: Dimens.fontMd,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
