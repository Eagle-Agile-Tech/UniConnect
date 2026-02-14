import 'package:flutter/material.dart';

class UCAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UCAppBar(this.title, {super.key,});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      elevation: 0,
      automaticallyImplyLeading: true,
      leading: IconButton.outlined(
        onPressed: null,
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(width: 1.5, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
