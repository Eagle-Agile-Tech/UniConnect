import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/common/widgets/back_button.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class UCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UCAppBar(
    this.title, {
    super.key,
    this.showBack = true,
    this.centerTitle = false,
  });

  final String title;
  final bool showBack;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: Dimens.sm,
      elevation: 0,
      automaticallyImplyLeading: showBack,
      centerTitle: centerTitle,
      leading: showBack ? UCBackButton() : null,
      leadingWidth: 80,
      title: Text(title, style: TextStyle(overflow: TextOverflow.ellipsis)),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}


