import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../config/assets.dart';
import '../../../../../../domain/models/comment/comment.dart';
import '../../../../../../utils/helper_functions.dart';
import '../../../../../home/view_models/comment_provider.dart';
import '../../../../theme/dimens.dart';

class CommentTile extends ConsumerWidget {
  final Comment comment;
  final String postId;
  final bool isReply;
  final String? parentCommentId;

  const CommentTile({
    super.key,
    required this.comment,
    required this.postId,
    this.isReply = false,
    this.parentCommentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(commentProvider(postId).notifier);
    ref.watch(commentProvider(postId));

    final avatarUrl = (comment.authorProfilePicUrl ?? '').trim();
    final avatarImage = avatarUrl.isNotEmpty
        ? NetworkImage(avatarUrl) as ImageProvider
        : const AssetImage(Assets.defaultAvatar);
    final repliesExpanded = notifier.isRepliesExpanded(comment.id);
    final repliesLoading = notifier.isRepliesLoading(comment.id);
    final replies = notifier.repliesFor(comment.id);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Dimens.sm,
        horizontal: Dimens.md + (isReply ? 28 : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 18, backgroundImage: avatarImage),
              const SizedBox(width: Dimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Dimens.sm,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          UCHelperFunctions.formatDateTime(comment.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: const TextStyle(height: 1.3)),
                    const SizedBox(height: Dimens.sm),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => notifier.toggleCommentLike(
                            commentId: comment.id,
                            parentCommentId: parentCommentId,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: _ActionButton(
                            comment.isLikedByMe
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            comment.likeCount.toString(),
                            color: comment.isLikedByMe
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                        ),
                        if (!isReply) ...[
                          const SizedBox(width: Dimens.md),
                          TextButton(
                            onPressed: () => notifier.startReply(comment),
                            child: const Text(
                              "Reply",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isReply && comment.replyCount > 0)
                      TextButton(
                        onPressed: () => notifier.toggleReplies(comment),
                        child: Text(
                          repliesExpanded
                              ? 'Hide replies'
                              : 'View replies (${comment.replyCount})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (!isReply && repliesExpanded && repliesLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (!isReply && repliesExpanded && replies.isNotEmpty)
                      ...replies.map(
                        (reply) => CommentTile(
                          comment: reply,
                          postId: postId,
                          isReply: true,
                          parentCommentId: comment.id,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ActionButton(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ],
      ),
    );
  }
}
