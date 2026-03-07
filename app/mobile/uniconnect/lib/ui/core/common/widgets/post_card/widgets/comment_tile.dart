import 'package:flutter/material.dart';

import '../../../../../../config/assets.dart';
import '../../../../../../domain/models/comment/comment.dart';
import '../../../../../../utils/helper_functions.dart';
import '../../../../theme/dimens.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimens.sm,
        horizontal: Dimens.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: comment.authorProfilePicUrl != null
                    ? NetworkImage(comment.authorProfilePicUrl!)
                    : const AssetImage(Assets.defaultAvatar),
              ),
              const SizedBox(width: Dimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Dimens.sm,
                      children: [
                        Text(comment.authorName,style: const TextStyle(fontWeight: FontWeight.bold),),
                        Text(UCHelperFunctions.formatDateTime(
                          comment.createdAt,
                        ), style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey))
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: const TextStyle(height: 1.3)),
                    const SizedBox(height: Dimens.sm),
                    Row(
                      children: [
                        _ActionButton(
                          Icons.thumb_up_outlined,
                          comment.likeCount.toString(),
                        ),
                        const SizedBox(width: Dimens.md),
                        _ActionButton(Icons.thumb_down_outlined, ""),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Reply",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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

  const _ActionButton(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}
