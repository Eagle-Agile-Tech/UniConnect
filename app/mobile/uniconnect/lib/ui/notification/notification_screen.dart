import 'package:flutter/material.dart';

import '../../config/assets.dart';
import '../core/theme/dimens.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))],
      ),
      body: ListView.separated(
        separatorBuilder: (context,index) => Divider(height: 1, color: Colors.grey[300]),
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              radius: Dimens.avatarXs,
              backgroundImage: AssetImage(Assets.googleLogo),
            ),
            title: Text(
              'EA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Dimens.fontMd,
                color: Colors.black87,
              ),
            ),
            subtitle: Text.rich(
              maxLines: 2,
              style: TextStyle(overflow: TextOverflow.ellipsis),
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Feisel: ',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'atp I\'m so proud of myself what do you mean, I have ice on my wrist',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            trailing: Text('2h ago'),
          );
        },
      ),
    );
  }
}
