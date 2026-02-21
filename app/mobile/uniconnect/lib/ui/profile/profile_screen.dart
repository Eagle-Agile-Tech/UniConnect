import 'package:flutter/material.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/common/styles/spacing_style.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../config/dummy_data.dart';
import '../core/common/widgets/post_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: Dimens.appBarHeight),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.defaultSpace,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: Dimens.avatarLg,
                            backgroundImage: const AssetImage(Assets.avatar1),
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withAlpha(30),
                          ),
                          const SizedBox(height: Dimens.sm),
                          Text(
                            '@Iman_',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
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
                              'Iman Yilma',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Jimma University',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            const SizedBox(height: Dimens.xs),
                            Text(
                              'Software Engineer',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: Dimens.sm),
                            Text(
                              'Smile | Over the Moon | Coffee Lover',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: Dimens.sm),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                        child: const Text('Follow'),
                      ),
                      const SizedBox(width: Dimens.sm),
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
                        child: const Text('Message'),
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
                  children: List.generate(5, (index) {
                    return Chip(
                      label: const Text('Flutter'),
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
            const SizedBox(height: Dimens.spaceBtwItems),
            UCPostCard(
              name: 'Iman Yilma',
              avatar: Assets.avatar1,
              caption: UCDummyData.postCaption1,
              image: Assets.post2,
            ),
            const SizedBox(height: Dimens.sm),
            UCPostCard(
              name: 'Iman Yilma',
              avatar: Assets.avatar1,
              caption: UCDummyData.postCaption1,
              image: Assets.post2,
            ),
          ],
        ),
      ),
    );
  }
}
