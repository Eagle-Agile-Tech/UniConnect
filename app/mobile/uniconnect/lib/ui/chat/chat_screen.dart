import 'package:flutter/material.dart';
import 'package:uniconnect/ui/chat/widgets/group_messages.dart';
import 'package:uniconnect/ui/chat/widgets/personal_messages.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../config/assets.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chat',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            overlayColor: WidgetStatePropertyAll(Colors.transparent),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderRadius: BorderRadius.circular(Dimens.radiusLg),
              borderSide: const BorderSide(width: 4),
              insets: EdgeInsetsGeometry.symmetric(horizontal: 95),
            ),
            tabs: const [
              Tab(text: 'Messages'),
              Tab(text: 'Groups'),
            ],
          ),
        ),
        body: TabBarView(children: [Messages(), GroupMessages()]),
      ),
    );
  }
}
