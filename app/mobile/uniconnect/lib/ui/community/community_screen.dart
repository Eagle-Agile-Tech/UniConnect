import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/community/view_models/community_viewmodel.dart';

import '../../config/assets.dart';
import '../../domain/models/community/community.dart';
import '../../domain/models/post/post.dart';
import '../../domain/models/user/user.dart';
import '../../routing/routes.dart';
import '../core/common/widgets/post_card/post_card.dart';
import '../core/theme/dimens.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({
    super.key,
    required this.communityId,
    required this.isCreated,
  });

  final String communityId;
  final bool isCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityAsync = ref.watch(singleCommunityProvider(communityId));
    final postAsync = ref.watch(communityPostsProvider(communityId));
    final memberAsync = ref.watch(communityMembersProvider(communityId));
    final membershipAction = ref.watch(
      communityMembershipActionProvider(communityId),
    );

    ref.listen(communityMembershipActionProvider(communityId), (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.invalidate(singleCommunityProvider(communityId));
          ref.invalidate(communityMembersProvider(communityId));
          ref.invalidate(communityPostsProvider(communityId));
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action failed: $error')),
          );
        },
      );
    });

    final isMembershipLoading = membershipAction is AsyncLoading;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                leading: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: isCreated
                      ? () => context.go(Routes.home)
                      : () => context.pop(),
                ),
                title: const Text(
                  'Community',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                pinned: true,
                floating: true,
                actions: [
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) => [
                      if(ref.read(authNotifierProvider).value!.user!.id == communityAsync.value?.ownerId)
                      PopupMenuItem(value: 'post', child: Text('Create Post')),
                      PopupMenuItem(value: 'leave', child: Text('Leave')),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'post':
                          context.push(Routes.communityCreatePost(communityId));
                          break;
                        case 'leave':
                          ref
                              .read(
                                communityMembershipActionProvider(communityId)
                                    .notifier,
                              )
                              .leave();
                          break;
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    communityAsync.when(
                      data: (Community data) {
                        return Column(
                          children: [
                            _buildHeaderImage(
                              data.profilePicture,
                              data.isMember,
                              isMembershipLoading,
                              () => ref
                                  .read(
                                    communityMembershipActionProvider(communityId)
                                        .notifier,
                                  )
                                  .join(),
                            ),
                            const SizedBox(height: Dimens.spaceBtwItems),
                            _buildCommunityInfo(context, data),
                          ],
                        );
                      },
                      error: (Object error, StackTrace stackTrace) =>
                          Center(child: Text(error.toString())),
                      loading: () => Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              ),

              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.purple,
                    tabs: [
                      Tab(text: 'Feed'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              postAsync.when(
                data: (List<Post> data) {
                  if (data.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(child: Text('No posts yet')),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) =>
                        UCPostCard(post: data[index]),
                  );
                },
                error: (Object error, StackTrace stackTrace) =>
                    Center(child: Text(error.toString())),
                loading: () => Center(child: CircularProgressIndicator()),
              ),
              memberAsync.when(
                data: (List<User> user) {
                  final ownerId = communityAsync.value?.ownerId;
                  return ListView.builder(
                    itemCount: user.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(Dimens.md),
                      child: ListTile(
                        onTap: () => context.push(Routes.userProfile(user[index].id)),
                        leading: CircleAvatar(
                          backgroundImage: user[index].profilePicture != null
                              ? NetworkImage(user[index].profilePicture!)
                              : const AssetImage(Assets.defaultAvatar),
                        ),
                        title: Text(user[index].fullName),
                        subtitle: Text('@${user[index].username}'),
                        trailing:
                            ownerId != null && ownerId == user[index].id
                            ? Container(
                                padding: EdgeInsets.all(Dimens.sm),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    Dimens.md,
                                  ),
                                  color: Color(0xFFe8edea),
                                ),
                                child: Text('Owner'),
                              )
                            : null,
                      ),
                    ),
                  );
                },
                error: (Object error, StackTrace stackTrace) =>
                    Center(child: Text(error.toString())),
                loading: () => Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(
    String? profileUrl,
    bool isMember,
    bool isLoading,
    VoidCallback onJoin,
  ) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: profileUrl != null
                  ? NetworkImage(profileUrl)
                  : AssetImage(Assets.defaultCommunityHeader),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(15, 35, 0, 0),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.tealAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: profileUrl != null
                    ? NetworkImage(profileUrl)
                    : AssetImage(Assets.defaultCommunityAvatar),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (!isMember)
          Positioned(
            right: 15,
            bottom: 0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: isLoading ? null : onJoin,
              child: const Text('Join', style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildCommunityInfo(BuildContext context, Community community) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            community.communityName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text('${community.members} members'),
          const SizedBox(height: Dimens.md),
          Text(community.description),
          const SizedBox(height: Dimens.spaceBtwItems),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
