import 'package:flutter/material.dart';

import '../../../../theme/dimens.dart';
import '../post_card.dart';
class ImageCarousel extends StatelessWidget {
  const ImageCarousel({
    super.key,
    required bool isExpanded,
    required CarouselController controller,
    required double imageWidth,
    required this.widget,
  }) : _isExpanded = isExpanded,
        _controller = controller,
        _imageWidth = imageWidth;

  final bool _isExpanded;
  final CarouselController _controller;
  final double _imageWidth;
  final UCPostCard widget;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            ...List.generate(widget.post.mediaUrls!.length, (index) {
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
    );
  }
}