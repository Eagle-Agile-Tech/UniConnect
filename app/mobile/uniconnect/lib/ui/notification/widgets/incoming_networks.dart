import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/network/viewmodels/network_provider.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import '../../../routing/routes.dart';
import '../view_models/notification_viewmodel.dart';

class NetworksIncomingScreen extends ConsumerWidget {
  const NetworksIncomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          ref.read(authNotifierProvider).value!.user!.fullName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: notificationAsync.when(
        data: (users) {
          if(users.isEmpty){
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_motion_rounded,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "No incoming requests",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    "You have no pending network requests at the moment.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final items = users[index];
              final user = items.$1;
              final requestId = items.$2;
              return ListTile(
                onTap: () => context.push(Routes.userProfile(user.id)),
                title: Text(user.fullName, style: TextStyle(
                    fontSize: Dimens.fontLg,
                    fontWeight: FontWeight.w600
                )),
                subtitle: Text('@${user.username}'),
                leading: CircleAvatar(
                  radius: Dimens.avatarSm,
                  backgroundImage: user.profilePicture == null
                      ? AssetImage(Assets.defaultAvatar)
                      : NetworkImage(user.profilePicture!),
                ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Accept network',
                        onPressed: () async {
                          final result = await ref
                              .read(networkActionProvider(requestId).notifier)
                              .acceptRequest();

                          result.fold(
                                (_) {
                                  ref.invalidate(notificationViewModelProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Network request Accepted')),
                              );
                            },
                                (error, _) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    UCHelperFunctions.getErrorMessage(error),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Reject network',
                        onPressed: () async {
                          final result = await ref
                              .read(networkActionProvider(requestId).notifier)
                              .rejectRequest();

                          result.fold(
                                (_) {
                                  ref.invalidate(notificationViewModelProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Network request rejected')),
                              );
                            },
                                (error, _) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    UCHelperFunctions.getErrorMessage(error),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  )
              );
            },
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
