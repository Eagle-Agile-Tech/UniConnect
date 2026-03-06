import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../../config/assets.dart';
import '../../../../domain/models/post/post.dart';
import '../../../../domain/models/user/user.dart';
import '../../theme/colors.dart';

class UCPostCard extends StatefulWidget {
  const UCPostCard({required this.author, required this.post, super.key});

  final User author;
  final Post post;

  @override
  State<UCPostCard> createState() => _UCPostCardState();
}

class _UCPostCardState extends State<UCPostCard> {
  bool _isExpanded = false;
  late CarouselController _controller;
  int _currentIndex = 0;

  double get _imageWidth => MediaQuery.of(context).size.width - 16;

  @override
  void initState() {
    super.initState();
    _controller = CarouselController(initialItem: 0);
    _controller.addListener(() {
      int animateTo = (_controller.offset / (_imageWidth)).round();
      animateTo = animateTo.clamp(0, widget.post.mediaUrls!.length - 1);
      if (animateTo != _currentIndex) {
        setState(() {
          _currentIndex = animateTo;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
            leading: CircleAvatar(
              backgroundImage: widget.author.profilePicture != null
                  ? NetworkImage(widget.author.profilePicture!)
                  : AssetImage(Assets.defaultAvatarWithBg),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (widget.post.content.length > 150 && !_isExpanded)
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
                if (widget.post.mediaUrls != null &&
                    widget.post.mediaUrls!.isNotEmpty)
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
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 4 / 5,
                      child: CarouselView(
                        controller: _controller,
                        itemExtent: _imageWidth,
                        shrinkExtent: _imageWidth,
                        itemSnapping: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Todo:  padding: EdgeInsets.all(100), looks amazing try it for real
                        padding: EdgeInsets.all(Dimens.sm),
                        children: [
                          ...List.generate(widget.post.mediaUrls!.length, (
                            index,
                          ) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.post.mediaUrls![index],
                                fit: BoxFit.cover,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                if (widget.post.mediaUrls != null &&
                    widget.post.mediaUrls!.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.post.mediaUrls!.length, (
                      index,
                    ) {
                      bool isActive = index == _currentIndex;
                      return InkWell(
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          _controller.animateTo(
                            index * _imageWidth,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(
                              Dimens.radiusSm,
                            ),
                          ),
                        ),
                      );
                    }),
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
