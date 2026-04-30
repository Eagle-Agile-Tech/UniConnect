import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/home/view_models/home_viewmodel_provider.dart';
import 'package:uniconnect/ui/home/widgets/drawer_content.dart';

import '../../routing/routes.dart';
import '../auth/auth_state_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(feedProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          'Uni',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.post),
            icon: const Icon(
              Icons.add_circle_outline_outlined,
              size: Dimens.iconLg,
            ),
          ),
        ],
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(Icons.sort, size: Dimens.iconSize),
          ),
        ),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 4,
        width: MediaQuery.of(context).size.width * 0.8,
        child: const DrawerContent(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .watch(
              feedProvider.notifier,
            )
            .refreshFeed(),
        child: postAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
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
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return UCPostCard(
                  post: posts[index],
                  onLike: () => ref
                      .read(
                        feedProvider.notifier,
                      )
                      .toggleLike(postId: posts[index].id),
                  onBookmark: () => ref
                      .read(
                        feedProvider.notifier,
                      )
                      .bookmarkPost(postId: posts[index].id),
                );
              },
            );
          },
          // Todo: make the error widget better
          error: (error, stackTrace) => Center(child: Text('Oops: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
