import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../config/assets.dart';

class Messages extends StatelessWidget {
  const Messages({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        onTap: () => context.push(Routes.messaging),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Dimens.md,
          vertical: Dimens.sm,
        ),
        leading: CircleAvatar(
          radius: Dimens.avatarXs,
          backgroundImage: AssetImage(Assets.avatar1),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: Dimens.xs),
          child: Text(
            'Iman Yilma',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Dimens.fontMd,
              color: Colors.black87,
            ),
          ),
        ),
        subtitle: Text(
          'So did you get me the bag?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Tue', style: TextStyle(fontSize: Dimens.fontSm, color: Colors.grey)),
            SizedBox(height: Dimens.xs),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '1',
                style: TextStyle(color: Colors.white, fontSize: Dimens.fontXs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
