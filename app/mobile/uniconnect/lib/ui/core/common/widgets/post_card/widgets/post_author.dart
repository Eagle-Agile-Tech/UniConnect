import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
          sheetAnimationStyle: AnimationStyle(
            duration: Duration(milliseconds: 500),
            reverseDuration: Duration(milliseconds: 400),
          ),
          builder: (context) {
            return Wrap(
              children: [
                ListTile(leading: Text('😞'), title: Text('Not Interested')),
                ListTile(leading: Text('🚩'), title: Text('Repost post')),
              ],
            );
          },
        ),
        icon: Icon(Icons.more_vert_outlined),
      ),
    );
  }
}