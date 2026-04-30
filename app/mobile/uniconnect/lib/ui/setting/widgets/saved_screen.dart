import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/post_card.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/setting/view_models/bookmark_provider.dart';

import '../../auth/auth_state_provider.dart';
import '../../home/view_models/home_viewmodel_provider.dart';


class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(bookmarkProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: postAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return Center(child: Text('No saved posts yet'));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return UCPostCard(
                  post: data[index],
                    onLike: () => ref.read(homeViewModelProvider(ref.read(authNotifierProvider).value!.user!.id).notifier).toggleLike(postId: data[index].id),
                    onBookmark: () => ref.read(homeViewModelProvider(ref.read(authNotifierProvider).value!.user!.id).notifier).bookmarkPost(postId: data[index].id
                    )
                    );
              },
            );
          },
          error: (error, stackTrace) =>
              Center(child: Text('Error loading saved posts')),
          loading: () => Padding(
            padding: const EdgeInsets.only(top: Dimens.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
