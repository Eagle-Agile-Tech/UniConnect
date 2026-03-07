import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/home/view_models/comment_provider.dart';

import '../../../../../../config/assets.dart';

class CommentInputArea extends ConsumerStatefulWidget {
  const CommentInputArea(this.postId, {super.key});

  final String postId;
  @override
  ConsumerState<CommentInputArea> createState() => _CommentInputAreaState();
}

class _CommentInputAreaState extends ConsumerState<CommentInputArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.read(commentProvider(widget.postId).notifier);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(Assets.defaultAvatar),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            IconButton(onPressed: () {
              if (_controller.text.trim().isNotEmpty || _controller.text.trim() !=  '') {
                viewModel.makeComment(content: _controller.text.trim());
              }
            }, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
