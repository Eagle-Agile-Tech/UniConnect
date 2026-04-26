import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/core/common/widgets/report/report_sheet.dart';
import 'package:uniconnect/ui/home/view_models/post_report_provider.dart';

import '../../../../../../config/assets.dart';
import '../../../../../../routing/routes.dart';
import '../post_card.dart';

class PostAuthor extends StatelessWidget {
  const PostAuthor({super.key, required this.widget});

  final UCPostCard widget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: GestureDetector(
        onTap: () => context.push(Routes.userProfile(widget.post.authorId)),
        child: CircleAvatar(
          backgroundImage: widget.post.authorProfilePicture != null
              ? NetworkImage(widget.post.authorProfilePicture!)
              : AssetImage(Assets.defaultAvatar),
        ),
      ),
      title: Text(
        widget.post.authorName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(DateFormat('hh:mm a').format(widget.post.createdAt)),
      trailing: IconButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          elevation: 10,
          useSafeArea: true,
          isDismissible: true,
          sheetAnimationStyle: AnimationStyle(
            duration: Duration(milliseconds: 500),
            reverseDuration: Duration(milliseconds: 400),
          ),
          builder: (context) {
            return Consumer(
              builder: (context, ref, child) {
                return Wrap(
                  children: [
                    if (widget.post.authorId ==
                        ref.read(authNotifierProvider).value!.user!.id)
                      ListTile(
                        leading: const Text('X'),
                        title: const Text('Remove Post'),
                        onTap: () {
                          context.pop();
                          widget.onDelete?.call();
                        },
                      ),
                    const ListTile(
                      leading: Text('😞'),
                      title: Text('Not Interested'),
                    ),
                    ListTile(
                      leading: const Text('🚩'),
                      title: const Text('Report Post'),
                      onTap: () {
                        context.pop();
                        _openReportSheet(context);
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        icon: Icon(Icons.more_vert_outlined),
      ),
    );
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => Consumer(
        builder: (context, ref, child) => ReportSheet(
          title: 'Report Post',
          onSubmit: (reason, message) {
            return ref
                .read(postReportActionProvider(widget.post.id).notifier)
                .reportPost(reason: reason, message: message);
          },
        ),
      ),
    );
  }
}
