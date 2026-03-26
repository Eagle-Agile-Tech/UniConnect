import 'package:flutter/material.dart';

import '../../../../theme/dimens.dart';

class PostCarouselIndicator extends StatelessWidget {
  const PostCarouselIndicator({
    super.key,
    required int currentIndex,
    required CarouselController controller,
    required double imageWidth,
    required int length,
  }) : _length = length,
       _currentIndex = currentIndex,
       _controller = controller,
       _imageWidth = imageWidth;

  final int _currentIndex;
  final CarouselController _controller;
  final double _imageWidth;
  final int _length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_length, (index) {
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
              color: isActive ? Theme.of(context).primaryColor : Colors.grey,
              borderRadius: BorderRadius.circular(Dimens.radiusSm),
            ),
          ),
        );
      }),
    );
  }
}
