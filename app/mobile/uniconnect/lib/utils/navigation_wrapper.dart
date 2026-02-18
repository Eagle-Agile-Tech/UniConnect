import 'package:flutter/material.dart';
import 'package:uniconnect/ui/home/home_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int selectedIndex = 0;
  final List<NavigationDestination> destinations = [
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
      icon: Badge(label: Text('5'), child: Icon(Icons.chat_bubble_outline)),
      label: 'Message',
      selectedIcon: Badge(label: Text('5'), child: Icon(Icons.chat_bubble)),
    ),
    const NavigationDestination(
      icon: Icon(Icons.notifications_none),
      label: 'Notifications',
      selectedIcon: Icon(Icons.notifications_rounded),
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      label: 'You',
      selectedIcon: Icon(Icons.person),
    ),
  ];

  final List<Widget> pages = [
    HomeScreen(),
    Container(color: Colors.green),
    Container(color: Colors.blue),
    Container(color: Colors.yellow),
    Container(color: Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
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
