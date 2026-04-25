import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/user/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/enums.dart';
import '../../../utils/helper_functions.dart';
import '../../auth/auth_state_provider.dart';
import '../../core/theme/dimens.dart';
import '../view_models/user_provider.dart';

class _NetworkPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _NetworkPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.lg, vertical: Dimens.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimens.radiusLg),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class MyNetwork extends ConsumerWidget {
  const MyNetwork({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.value?.user;

    return _NetworkPill(
      onTap: () {
        if (currentUser != null) {
          ref.read(selectedUserProfileProvider.notifier).state = currentUser;
          context.push(Routes.networks);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            UCHelperFunctions.formatMembers(50500),
            style: TextStyle(
              fontSize: Dimens.fontMd,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: Dimens.sm),
          const Text(
            'Network',
            style: TextStyle(
              fontSize: Dimens.fontMd,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OthersNetwork extends ConsumerWidget {
  const OthersNetwork({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: Dimens.sm,
      runSpacing: Dimens.sm,
      children: [
        _NetworkPill(
          onTap: user.networkStatus != null ? () {
            ref.read(selectedUserProfileProvider.notifier).state = user;
            context.push(Routes.networks);
          } : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.networkCount > 0) ...[
                Text(
                  UCHelperFunctions.formatMembers(user.networkCount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: Dimens.xs),
              ],
              Text(
                user.networkStatus == NetworkStatus.CONNECTED ? 'Linked' : user.networkStatus == NetworkStatus.PENDING ? 'Sent' : 'Network',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: user.networkStatus == null ? null : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        _NetworkPill(
          onTap: () => context.push(
            Routes.messaging,
            extra: {
              'receiverId': user.id,
              'username': user.fullName,
              'profileImage': user.profilePicture
            },
          ),
          child: const Text(
            'Chat',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}