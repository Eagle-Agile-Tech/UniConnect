import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/domain/models/user/user.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/profile/view_models/profile_viewmodel_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/ui/profile/widgets/profile_header.dart';

import '../../config/dummy_data.dart';
import '../core/common/widgets/post_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final postAsync = ref.watch(profileViewModelProvider);
    if (user == null) {
      return Scaffold(body: Center(child: const Text('No User')));
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(profileViewModelProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: Dimens.appBarHeight),
                child: ProfileHeader(),
              ),
            ),
            postAsync.when(
              data: (posts) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      UCPostCard(author: user, post: posts[index]),
                  childCount: posts.length
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


