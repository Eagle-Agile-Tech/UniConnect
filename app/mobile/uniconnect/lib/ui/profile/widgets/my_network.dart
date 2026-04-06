import 'package:flutter/material.dart';

import '../../../utils/helper_functions.dart';
import '../../core/theme/dimens.dart';

class MyNetwork extends StatelessWidget {
  const MyNetwork({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: EdgeInsets.all(Dimens.md),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ]
      ),
      child: Row(
          children: [
            Text(UCHelperFunctions.formatMembers(50500),style: TextStyle(
                fontSize: Dimens.fontMd,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold
            ),),
            const SizedBox(width:Dimens.spaceBtwItems),
            Text('Networks', style: TextStyle(
              fontSize: Dimens.fontMd,
              fontWeight: FontWeight.w600,
            ))
          ]
      ),
    );
  }
}