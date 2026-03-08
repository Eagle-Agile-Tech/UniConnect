import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/widgets/comment_field.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/widgets/comment_tile.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/widgets/image_carousel_view.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/widgets/post_author.dart';
import 'package:uniconnect/ui/core/common/widgets/post_card/widgets/post_carousel.dart';
import 'package:uniconnect/ui/home/view_models/comment_provider.dart';
import 'package:uniconnect/ui/home/view_models/home_viewmodel_provider.dart';

import '../../../../../domain/models/post/post.dart';
import '../../../../../domain/models/user/user.dart';
import '../../../theme/colors.dart';

class UCPostCard extends ConsumerStatefulWidget {
  const UCPostCard({required this.author, required this.post, super.key});

  final User author;
  final Post post;

  @override
  ConsumerState<UCPostCard> createState() => _UCPostCardState();
}

class _UCPostCardState extends ConsumerState<UCPostCard> {
  bool _isExpanded = false;
  late CarouselController _controller;
  int _currentIndex = 0;
  String comment = '';

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
    final viewModel = ref.read(homeViewModelProvider.notifier);
    return Card(
      borderOnForeground: true,
      color: UCColors.background,
      elevation: 1.5,
      child: Column(
        spacing: 5,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PostAuthor(widget: widget),
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
                  ImageCarousel(
                    isExpanded: _isExpanded,
                    controller: _controller,
                    imageWidth: _imageWidth,
                    widget: widget,
                  ),

                if (widget.post.mediaUrls != null &&
                    widget.post.mediaUrls!.length > 1)
                  PostCarouselIndicator(
                    widget: widget,
                    currentIndex: _currentIndex,
                    controller: _controller,
                    imageWidth: _imageWidth,
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () =>
                          viewModel.toggleLike(postId: widget.post.id),
                      icon: Icon(
                        widget.post.isLikedByMe == true
                            ? Icons.thumb_up
                            : Icons.thumb_up_alt_outlined,
                        color: widget.post.isLikedByMe == true
                            ? Colors.red
                            : null,
                      ),
                    ),
                    Text('${widget.post.likeCount}'),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined),
                      //todo: make the comments lazily load when the button is pressed
                      //todo: use animation effect when the modal appears then the comments are loaded
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        useSafeArea: true,
                        isScrollControlled: true,
                        builder: (context) {
                          return Consumer(
                            builder:
                                (
                                  BuildContext context,
                                  WidgetRef ref,
                                  Widget? child,
                                ) {
                                  final commentAsync = ref.watch(
                                    commentProvider(widget.post.id),
                                  );
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(
                                        context,
                                      ).viewInsets.bottom,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: commentAsync.when(
                                            data: (comments) =>
                                                ListView.separated(
                                                  itemCount: comments.length,
                                                  separatorBuilder: (_, _) =>
                                                      const Divider(
                                                        indent: 70,
                                                        height: 1,
                                                        color: Colors.black12,
                                                      ),
                                                  itemBuilder:
                                                      (context, index) =>
                                                          CommentTile(
                                                            comment:
                                                                comments[index],
                                                          ),
                                                ),
                                            error: (error, _) => Center(
                                              child: Text(error.toString()),
                                            ),
                                            loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ),
                                        CommentInputArea(widget.post.id),
                                      ],
                                    ),
                                  );
                                },
                          );
                        },
                      ),
                    ),
                    Text(widget.post.commentCount.toString()),
                    // todo: implement share functionality within the app only
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () =>
                          viewModel.bookmarkPost(postId: widget.post.id),
                      icon: widget.post.isBookmarkedByMe ? Icon(Icons.bookmark) : Icon(Icons.bookmark_border_outlined),
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
