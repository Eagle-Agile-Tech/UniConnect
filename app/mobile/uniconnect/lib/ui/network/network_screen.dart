import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/config/assets.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/network/viewmodels/network_provider.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/profile/view_models/user_provider.dart';
import 'package:uniconnect/utils/helper_functions.dart';

import '../../routing/routes.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(selectedUserProfileProvider)!;
    final authState = ref.watch(authNotifierProvider);
    final canManageConnections = authState.value?.user?.id == user.id;
    final networksAsync = ref.watch(networksProvider(user.id));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          user.fullName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: networksAsync.when(
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
                    "No connection so far",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    "Seize the moment at the moment.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () => context.push(Routes.userProfile(users[index].id)),
                title: Text(users[index].fullName, style: TextStyle(
                  fontSize: Dimens.fontLg,
                  fontWeight: FontWeight.w600
                )),
                subtitle: Text('@${users[index].username}'),
                leading: CircleAvatar(
                  radius: Dimens.avatarSm,
                  backgroundImage: users[index].profilePicture == null
                      ? AssetImage(Assets.defaultAvatar)
                      : NetworkImage(users[index].profilePicture!),
                ),
                trailing: canManageConnections
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_outlined),
                        tooltip: 'Remove from network',
                        onPressed: () async {
                          final result = await ref
                              .read(networksProvider(user.id).notifier)
                              .removeConnection(users[index].id);

                          result.fold(
                            (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Connection removed'),
                                ),
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
                      )
                    : null,
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
