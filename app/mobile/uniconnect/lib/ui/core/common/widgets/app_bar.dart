import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class UCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UCAppBar(this.title, {super.key, this.showBack = true});

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      elevation: 0,
      automaticallyImplyLeading: true,
      title: Padding(
        padding: const EdgeInsetsGeometry.symmetric(
          horizontal: Dimens.spaceBtwHeader,
        ),
        child: Row(
          children: [
            if (showBack) ...[
              GestureDetector(
                onTap: null,
                child: Container(
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
              ),
              const SizedBox(width: Dimens.spaceBtwItems),
            ],
            Text(title, style: TextStyle(overflow: TextOverflow.ellipsis),),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
