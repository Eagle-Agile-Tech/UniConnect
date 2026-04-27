import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/utils/enums.dart';

import '../../routing/routes.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value!.user!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings and activity'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your account
            ListTile(
              horizontalTitleGap: Dimens.xl,
              title: Text(
                'Your Account',
                style: TextStyle().copyWith(fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.person),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: Dimens.sm),
                child: Text('See information about your account '),
              ),
              onTap: () => context.push(Routes.manageProfile),
            ),
            // Heading
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.defaultSpace,
                  vertical: Dimens.sm,
                ),
                child: Text(
                  'Activity',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.copyWith(color: Colors.grey),
                ),
              ),
            ),
            // Activity
            ListTile(
              leading: Icon(Icons.bookmark_border_outlined),
              title: Text('Saved'),
              trailing: Icon(Icons.keyboard_arrow_right_outlined),
              onTap: () => context.push(Routes.saved),
            ),
            ListTile(
              leading: Icon(Icons.event_available_outlined),
              title: Text('Events'),
              trailing: Icon(Icons.keyboard_arrow_right_outlined),
              onTap: () => context.push(Routes.events()),
            ),
            if (user.role == UserRole.INSTITUTION)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.defaultSpace,
                  vertical: Dimens.sm,
                ),
                child: Text(
                  'Affiliation',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall!.copyWith(color: Colors.grey),
                ),
              ),
            ),
            // Activity
            if (user.role == UserRole.INSTITUTION)
              ListTile(
              leading: Icon(Icons.people_outline),
              title: Text('Affiliates'),
              trailing: Icon(Icons.keyboard_arrow_right_outlined),
              onTap: () => context.push(Routes.affiliate),
            ),
          ],
        ),
      ),
    );
  }
}
