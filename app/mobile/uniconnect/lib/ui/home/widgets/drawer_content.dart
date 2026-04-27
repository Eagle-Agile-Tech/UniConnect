import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

import '../../../config/theme_provider.dart';
import '../../../routing/routes.dart';

class DrawerContent extends ConsumerWidget {
  const DrawerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final currentMode = themeAsync.value ?? ThemeMode.system;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        ListTile(
          title: Text('Create a community'),
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () => context.push(Routes.createCommunity),
          ),
        ),
        Divider(),
        ListTile(
          title: Text('Recently Visited'),
          trailing: Icon(Icons.keyboard_arrow_right),
        ),
        ListTile(
          title: Text('Your Communities'),
          trailing: Icon(Icons.keyboard_arrow_right),
        ),
        Spacer(),
        ListTile(
          leading: Icon(currentMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          title: const Text("Brightness"),
          onTap: () {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),

        Divider(thickness: 1),
        ListTile(title: Text('UniConnect Rules'), leading: Icon(Icons.rule)),
        ListTile(
          title: Text('Privacy Policy'),
          leading: Icon(Icons.privacy_tip),
        ),
      ],
    );
  }
}
