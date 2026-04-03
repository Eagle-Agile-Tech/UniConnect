
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository_remote.dart';
import 'package:uniconnect/domain/models/post/post.dart';

final profileViewModelProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repo = ref.watch(postRemoteProvider);
  final result = await repo.getUserPost(userId);
  return result.fold(
        (data) => data,
        (error, stackTrace) => throw error,
  );
});