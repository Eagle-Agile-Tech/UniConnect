import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../config/assets.dart';
import '../post_card.dart';

class PostAuthor extends StatelessWidget {
  const PostAuthor({super.key, required this.widget});

  final UCPostCard widget;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.author.profilePicture != null
            ? NetworkImage(widget.author.profilePicture!)
            : AssetImage(Assets.defaultAvatar),
      ),
      title: Text(
        widget.author.fullName,
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