import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository_remote.dart';
import 'package:uniconnect/domain/models/post/post.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';

final profileViewModelProvider = AsyncNotifierProvider<ProfileViewModel, List<Post>>(
  ProfileViewModel.new
);

class ProfileViewModel extends AsyncNotifier<List<Post>>{
  @override
  FutureOr<List<Post>> build() async{
    final userId = ref.watch(userProvider)?.id;
    if(userId == null) return [];
    final result = await ref.read(postProvider).getUserPost(userId);
    return result.fold(
      (posts) => posts,
      (error, stackTrace) => throw error);
  }

}