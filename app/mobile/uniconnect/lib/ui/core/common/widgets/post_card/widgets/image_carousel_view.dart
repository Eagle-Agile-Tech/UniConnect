import 'package:flutter/material.dart';

import '../../../../theme/dimens.dart';

class ImageCarousel extends StatelessWidget {
  const ImageCarousel({
    super.key,
    required bool isExpanded,
    required CarouselController controller,
    required List<String> images,
  }) : _images = images,
       _isExpanded = isExpanded,
       _controller = controller;

  final bool _isExpanded;
  final CarouselController _controller;
  final List<String> _images;

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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return CarouselView(
              controller: _controller,
              itemExtent: constraints.maxWidth,
              itemSnapping: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // Todo:  padding: EdgeInsets.all(100), looks amazing try it for real
              padding: EdgeInsets.all(Dimens.sm),
              children: [
                ...List.generate(_images.length, (index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_images[index], fit: BoxFit.cover),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
