import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/community/view_models/community_viewmodel.dart';
import 'package:uniconnect/utils/helper_functions.dart';
import '../../domain/models/community/community.dart';
import '../../routing/routes.dart';
import '../core/theme/dimens.dart';

class ExploreCommunityScreen extends ConsumerWidget {
  const ExploreCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topCommunitiesAsync = ref.watch(communityProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Explore',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, size: Dimens.iconLg),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Top Communities'),
            topCommunitiesAsync.when(
              data: (topCommunities) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.defaultSpace,
                ),
                itemCount: math.min(5, topCommunities.length),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  Community community = topCommunities[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      onTap:() => context.push(Routes.community(community.id),extra: false),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: community.profilePicture != null
                            ? Image.network(
                                community.profilePicture!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                Assets.community,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                      ),
                      title: Text(
                        community.communityName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(community.university),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          UCHelperFunctions.formatMembers(community.members),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              loading: () => Center(child: CircularProgressIndicator()),
            ),
            // const SizedBox(height: 24),
            // const _SectionHeader(title: 'Picked for You'),
            // _HorizontalCommunityList(),
            // const SizedBox(height: 24),
            // const _SectionHeader(title: 'New Communities'),
            // _HorizontalCommunityList(),
            // const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.defaultSpace,
        8,
        Dimens.defaultSpace,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          // TextButton(onPressed: () {}, child: const Text('See All')),
        ],
      ),
    );
  }
}

class _HorizontalCommunityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimens.defaultSpace),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: AssetImage(Assets.event),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tech Savvies',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
