import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
class UCBackButton extends StatelessWidget {
  const UCBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimens.sm),
      child: Container(
        margin: EdgeInsets.only(left: Dimens.spaceBtwHeader),
        height: Dimens.iconSize,
        width: Dimens.iconSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: Dimens.iconMd,
          color: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}