import 'package:flutter/material.dart';

import '../../core/theme/dimens.dart';

class ExploreItem extends StatelessWidget {
  const ExploreItem({super.key, required this.color, required this.image, required this.title});

  final Color color;
  final String image;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: Dimens.sm, left: Dimens.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Positioned(
            bottom: -11,
            right: -11,
            child: Transform.rotate(
              angle: 10 * (3.14 / 180),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  image,
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
