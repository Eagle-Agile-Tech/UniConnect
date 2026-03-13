import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/profile/view_models/profile_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/ui/profile/widgets/profile_header.dart';

import '../../domain/models/user/user.dart';
import '../core/common/widgets/post_card/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider)!;
    final String activeId = userId ?? currentUser.id;

    final bool isMe = userId == null ? true : false;

    final AsyncValue<User> user = userId == null
        ? AsyncValue.data(currentUser)
        : ref.watch(userProvider(userId!));

    final postAsync = userId == null
        ? ref.watch(profileViewModelProvider(currentUser.id))
        : ref.watch(profileViewModelProvider(userId!));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(profileViewModelProvider(activeId).future),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: Dimens.sm),
                child: isMe
                    ? ProfileHeader(user: currentUser, isMe: true)
                    : user.when(
                        data: (User data) =>
                            ProfileHeader(user: data, isMe: false),
                        error: (Object error, StackTrace stackTrace) =>
                            Center(child: Text('Error: $error')),
                        loading: () =>
                            Center(child: CircularProgressIndicator()),
                      ),
              ),
            ),
            postAsync.when(
              data: (posts) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => UCPostCard(post: posts[index]),
                  childCount: posts.length,
                ),
              ),
              error: (err, stack) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
