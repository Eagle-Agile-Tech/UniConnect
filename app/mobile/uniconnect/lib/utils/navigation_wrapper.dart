import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/chat/widgets/direct_chats.dart';
import 'package:uniconnect/ui/explore/explore_screen.dart';
import 'package:uniconnect/ui/home/home_screen.dart';
import 'package:uniconnect/ui/profile/profile_screen.dart';
import 'package:uniconnect/ui/notification/view_models/notification_viewmodel.dart';

import '../ui/notification/notification_screen.dart';

class NavigationWrapper extends ConsumerStatefulWidget {
  const NavigationWrapper({super.key});

  @override
  ConsumerState<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends ConsumerState<NavigationWrapper> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ExploreScreen(),
    DirectChatScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationViewModelProvider);
    // final unreadCount = notifications.value?.unreadCount ?? 0;
     final unreadCount = 0;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Home',
        selectedIcon: Icon(Icons.home_filled),
      ),
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        label: 'Explore',
        selectedIcon: Icon(Icons.explore),
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Message',
        selectedIcon: Icon(Icons.chat_bubble),
      ),
      NavigationDestination(
        icon: _NotificationIcon(unreadCount: unreadCount, selected: false),
        label: 'Notification',
        selectedIcon: _NotificationIcon(unreadCount: unreadCount, selected: true),
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'You',
        selectedIcon: Icon(Icons.person),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 65,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.unreadCount, required this.selected});

  final int unreadCount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.notifications_rounded : Icons.notifications_none,
    );
    if (unreadCount <= 0) {
      return icon;
    }
    final label = unreadCount > 99 ? '99+' : unreadCount.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -6,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
