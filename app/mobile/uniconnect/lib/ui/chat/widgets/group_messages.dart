import 'package:flutter/material.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

class GroupMessages extends StatelessWidget {
  const GroupMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: Dimens.md,
            vertical: Dimens.sm,
          ),
          leading: CircleAvatar(
            radius: Dimens.avatarSm,
            backgroundImage: AssetImage(Assets.event),
          ),
          title: Padding(
            padding: EdgeInsets.only(bottom: Dimens.sm),
            child: const Text(
              'Eagle Agile',
              style: TextStyle(
                fontSize: Dimens.fontMd,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          subtitle: Text.rich(
            maxLines: 1,
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
                  text: 'I have the bag Iman, I will bring it to you tomorrow.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tue',
                style: TextStyle(fontSize: Dimens.fontSm, color: Colors.grey),
              ),
              SizedBox(height: Dimens.xs),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Dimens.fontXs,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
