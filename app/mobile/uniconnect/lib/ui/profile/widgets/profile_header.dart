import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/assets.dart';
import '../../../domain/models/user/user.dart';
import '../../../routing/routes.dart';
import '../../core/theme/dimens.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.user, required this.isMe});

  final User user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (isMe)
          Align(
            alignment: AlignmentGeometry.topEnd,
            child: IconButton(
              onPressed: () => context.push(Routes.setting),
              icon: const Icon(Icons.settings),
            ),
          ),
        if (!isMe)
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.defaultSpace),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: Dimens.avatarLg,
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : AssetImage(Assets.defaultAvatar),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withAlpha(30),
                      ),
                      const SizedBox(height: Dimens.sm),
                      Text(
                        "@${user.username}",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: Dimens.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.university,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: Dimens.xs),
                        Text(
                          user.degree,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: Dimens.sm),
                        Text(
                          user.bio ?? 'No bio available',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Dimens.md),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.lg,
                                  vertical: Dimens.sm,
                                ),
                              ),
                              child: const Text('Network'),
                            ),
                            const SizedBox(width: Dimens.sm),
                            ElevatedButton(
                              onPressed: () => context.push(
                                Routes.messaging,
                                extra: {
                                  'userId': user.id,
                                  'username': user.username,
                                },
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.lg,
                                  vertical: Dimens.sm,
                                ),
                              ),
                              child: const Text('Chat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        const SizedBox(height: Dimens.md),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Interests',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: Dimens.sm),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: Dimens.sm,
              runSpacing: Dimens.sm,
              children: List.generate(user.interests!.length, (index) {
                return Chip(
                  label: Text(user.interests![index]),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withAlpha(50),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimens.sm),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
