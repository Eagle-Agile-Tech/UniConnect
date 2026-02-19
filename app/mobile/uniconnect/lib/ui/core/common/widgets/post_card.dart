import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class UCPostCard extends StatefulWidget {
  const UCPostCard({
    required this.caption,
    required this.avatar,
    required this.name,
    required this.image,
    super.key,
  });

  final String caption;
  final String avatar;
  final String name;
  final String image;

  @override
  State<UCPostCard> createState() => _UCPostCardState();
}

class _UCPostCardState extends State<UCPostCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      borderOnForeground: true,
      color: UCColors.background,
      elevation: 1.5,
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: AssetImage(widget.avatar)),
            title: Text(
              widget.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('08:39 AM'),
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
                      ListTile(
                        leading: Text('😞'),
                        title: Text('Not Interested'),
                      ),
                      ListTile(leading: Text('🚩'), title: Text('Repost post')),
                    ],
                  );
                },
              ),
              icon: Icon(Icons.more_vert_outlined),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              spacing: 5,
              children: [
                Text(
                  widget.caption,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (widget.caption.length > 150 && !_isExpanded)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        'Show More',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                Container(
                  margin: EdgeInsets.only(top: _isExpanded ? 3 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(widget.image, fit: BoxFit.cover),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.thumb_up_outlined),
                    ),
                    const Text('123'),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.comment_outlined),
                    ),
                    const Text('123'),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
