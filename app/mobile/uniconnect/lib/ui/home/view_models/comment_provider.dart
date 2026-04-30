import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/data/repository/post/post_repository.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';

import '../../../data/repository/post/post_repository_remote.dart';
import '../../../domain/models/comment/comment.dart';

final commentProvider = AsyncNotifierProvider.autoDispose
    .family<CommentNotifier, List<Comment>, String>(CommentNotifier.new);

class CommentNotifier extends AsyncNotifier<List<Comment>> {
  CommentNotifier(this.postId);

  final String postId;
  late PostRepository _postRepo;
  String? _nextCommentCursor;
  bool _hasMoreComments = true;
  bool _isLoadingMoreComments = false;

  final Map<String, List<Comment>> _repliesByCommentId = {};
  final Map<String, String?> _nextReplyCursorByCommentId = {};
  final Set<String> _expandedCommentIds = {};
  final Set<String> _loadingReplyCommentIds = {};

  String? _activeReplyParentId;
  String? _activeReplyAuthorName;

  bool get isLoadingMoreComments => _isLoadingMoreComments;
  bool get hasMoreComments => _hasMoreComments;
  bool isRepliesExpanded(String commentId) =>
      _expandedCommentIds.contains(commentId);
  bool isRepliesLoading(String commentId) =>
      _loadingReplyCommentIds.contains(commentId);
  List<Comment> repliesFor(String commentId) =>
      _repliesByCommentId[commentId] ?? const [];
  String? get activeReplyParentId => _activeReplyParentId;
  String? get activeReplyAuthorName => _activeReplyAuthorName;

  @override
  FutureOr<List<Comment>> build() async {
    _postRepo = ref.watch(postRemoteProvider);
    final result = await _postRepo.getComments(postId);
    return result.fold(
      (payload) {
        final comments =
            (payload['data'] as List?)?.whereType<Comment>().toList() ??
            const <Comment>[];
        final pagination = payload['pagination'];
        if (pagination is Map) {
          _nextCommentCursor = pagination['nextCursor']?.toString();
          _hasMoreComments = pagination['hasMore'] == true;
        } else {
          _nextCommentCursor = null;
          _hasMoreComments = false;
        }
        return comments;
      },
      (error, stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current),
    );
  }

  void _refreshState() {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data([...current]);
    }
  }

  Future<void> loadMoreComments() async {
    if (_isLoadingMoreComments ||
        !_hasMoreComments ||
        _nextCommentCursor == null) {
      return;
    }

    final previous = state.value ?? const <Comment>[];
    _isLoadingMoreComments = true;
    _refreshState();

    final result = await _postRepo.getComments(
      postId,
      cursor: _nextCommentCursor,
    );

    result.fold(
      (payload) {
        final newComments =
            (payload['data'] as List?)?.whereType<Comment>().toList() ??
            const <Comment>[];
        final pagination = payload['pagination'];
        if (pagination is Map) {
          _nextCommentCursor = pagination['nextCursor']?.toString();
          _hasMoreComments = pagination['hasMore'] == true;
        } else {
          _nextCommentCursor = null;
          _hasMoreComments = false;
        }
        state = AsyncValue.data([...previous, ...newComments]);
      },
      (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
        state = AsyncValue.data(previous);
      },
    );

    _isLoadingMoreComments = false;
    _refreshState();
  }

  void startReply(Comment parent) {
    _activeReplyParentId = parent.id;
    _activeReplyAuthorName = parent.authorName;
    _refreshState();
  }

  void cancelReply() {
    _activeReplyParentId = null;
    _activeReplyAuthorName = null;
    _refreshState();
  }

  Future<void> toggleReplies(Comment parent) async {
    if (_expandedCommentIds.contains(parent.id)) {
      _expandedCommentIds.remove(parent.id);
      _refreshState();
      return;
    }

    _expandedCommentIds.add(parent.id);
    _refreshState();

    if ((_repliesByCommentId[parent.id] ?? const <Comment>[]).isEmpty) {
      await loadReplies(parent.id);
    }
  }

  Future<void> loadReplies(String parentCommentId) async {
    if (_loadingReplyCommentIds.contains(parentCommentId)) return;

    _loadingReplyCommentIds.add(parentCommentId);
    _refreshState();

    final result = await _postRepo.getReplies(
      commentId: parentCommentId,
      cursor: _nextReplyCursorByCommentId[parentCommentId],
    );

    result.fold((payload) {
      final replies =
          (payload['data'] as List?)?.whereType<Comment>().toList() ??
          const <Comment>[];
      final existing =
          _repliesByCommentId[parentCommentId] ?? const <Comment>[];
      _repliesByCommentId[parentCommentId] = [
        ...existing,
        ...replies.where((reply) => existing.every((it) => it.id != reply.id)),
      ];
      final pagination = payload['pagination'];
      if (pagination is Map) {
        _nextReplyCursorByCommentId[parentCommentId] = pagination['nextCursor']
            ?.toString();
      }
    }, (error, stackTrace) {});

    _loadingReplyCommentIds.remove(parentCommentId);
    _refreshState();
  }

  Future<void> submitComment({required String content}) async {
    final previous = state.value ?? const <Comment>[];
    final auth = ref.read(authNotifierProvider).value?.user;
    if (auth == null) return;

    final parentCommentId = _activeReplyParentId;
    final tempComment = Comment(
      id: 'temp-${DateTime.now().microsecondsSinceEpoch}',
      parentCommentId: parentCommentId,
      content: content,
      postId: postId,
      authorId: auth.id,
      authorName: auth.fullName,
      authorProfilePicUrl: auth.profilePicture,
      createdAt: DateTime.now(),
      likeCount: 0,
      replyCount: 0,
      isLikedByMe: false,
    );

    if (parentCommentId == null) {
      state = AsyncValue.data([tempComment, ...previous]);
    } else {
      final existingReplies =
          _repliesByCommentId[parentCommentId] ?? const <Comment>[];
      _repliesByCommentId[parentCommentId] = [...existingReplies, tempComment];
      _expandedCommentIds.add(parentCommentId);
      state = AsyncValue.data(
        previous.map((c) {
          if (c.id == parentCommentId) {
            return c.copyWith(replyCount: c.replyCount + 1);
          }
          return c;
        }).toList(),
      );
    }

    cancelReply();

    final result = await _postRepo.commentOnPost(
      postId: postId,
      comment: content,
      createdAt: DateTime.now(),
      authorId: auth.id,
      parentCommentId: parentCommentId,
    );

    result.fold(
      (createdComment) {
        if (parentCommentId == null) {
          state = AsyncValue.data([
            createdComment,
            ...((state.value ?? const <Comment>[]).where(
              (c) => c.id != tempComment.id,
            )),
          ]);
          return;
        }

        final replies =
            _repliesByCommentId[parentCommentId] ?? const <Comment>[];
        _repliesByCommentId[parentCommentId] = [
          ...replies.where((reply) => reply.id != tempComment.id),
          createdComment,
        ];
        _refreshState();
        build();
      },
      (error, stackTrace) {
        if (parentCommentId == null) {
          state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
          state = AsyncValue.data(previous);
          return;
        }

        _repliesByCommentId[parentCommentId] =
            (_repliesByCommentId[parentCommentId] ?? const <Comment>[])
                .where((reply) => reply.id != tempComment.id)
                .toList();

        state = AsyncValue.data(
          previous.map((c) {
            if (c.id == parentCommentId) {
              return c.copyWith(
                replyCount: c.replyCount > 0 ? c.replyCount - 1 : 0,
              );
            }
            return c;
          }).toList(),
        );
        state = AsyncValue.error(error, stackTrace ?? StackTrace.current);
        state = AsyncValue.data(previous);
      },
    );
  }

  Future<void> toggleCommentLike({
    required String commentId,
    String? parentCommentId,
  }) async {
    final comments = state.value;
    if (comments == null) return;

    if (parentCommentId == null) {
      final index = comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return;

      final target = comments[index];
      final optimistic = target.copyWith(
        isLikedByMe: !target.isLikedByMe,
        likeCount: target.isLikedByMe
            ? (target.likeCount > 0 ? target.likeCount - 1 : 0)
            : target.likeCount + 1,
      );
      final optimisticComments = [...comments]..[index] = optimistic;
      state = AsyncValue.data(optimisticComments);

      final result = await _postRepo.toggleCommentReaction(
        commentId: commentId,
      );
      result.fold(
        (payload) {
          final reacted = payload['reacted'] == true;
          final reactionCount =
              (payload['reactionCount'] as num?)?.toInt() ??
              optimistic.likeCount;
          final updated = (state.value ?? optimisticComments).map((c) {
            if (c.id == commentId) {
              return c.copyWith(isLikedByMe: reacted, likeCount: reactionCount);
            }
            return c;
          }).toList();
          state = AsyncValue.data(updated);
        },
        (error, stackTrace) {
          state = AsyncValue.data(comments);
        },
      );
      return;
    }

    final replies = _repliesByCommentId[parentCommentId] ?? const <Comment>[];
    final idx = replies.indexWhere((reply) => reply.id == commentId);
    if (idx == -1) return;

    final target = replies[idx];
    final optimistic = target.copyWith(
      isLikedByMe: !target.isLikedByMe,
      likeCount: target.isLikedByMe
          ? (target.likeCount > 0 ? target.likeCount - 1 : 0)
          : target.likeCount + 1,
    );
    _repliesByCommentId[parentCommentId] = [
      ...replies.sublist(0, idx),
      optimistic,
      ...replies.sublist(idx + 1),
    ];
    _refreshState();

    final result = await _postRepo.toggleCommentReaction(commentId: commentId);
    result.fold(
      (payload) {
        final reacted = payload['reacted'] == true;
        final reactionCount =
            (payload['reactionCount'] as num?)?.toInt() ?? optimistic.likeCount;
        final currentReplies =
            _repliesByCommentId[parentCommentId] ?? const <Comment>[];
        _repliesByCommentId[parentCommentId] = currentReplies.map((reply) {
          if (reply.id == commentId) {
            return reply.copyWith(
              isLikedByMe: reacted,
              likeCount: reactionCount,
            );
          }
          return reply;
        }).toList();
        _refreshState();
      },
      (error, stackTrace) {
        _repliesByCommentId[parentCommentId] = replies;
        _refreshState();
      },
    );
  }

  @Deprecated('Use submitComment')
  Future<void> makeComment({required String content}) async {
    await submitComment(content: content);
  }
}
