import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/assets.dart';
import '../../../domain/models/user/user.dart';
import '../../../routing/routes.dart';
import '../../../utils/enums.dart';
import '../../../utils/result.dart';
import '../../core/common/widgets/report/report_sheet.dart';
import '../../core/theme/dimens.dart';
import '../../network/viewmodels/network_provider.dart';
import '../view_models/user_provider.dart';
import 'my_network.dart';
import 'others_network.dart' hide MyNetwork;

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.user, required this.isMe});

  final User user;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkActionState = ref.watch(networkActionProvider(user.id));
    return Column(
      children: [
        Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.spaceBetween,
          children: [
            if (!isMe)
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
            isMe
                ? IconButton(
                    onPressed: () => context.push(Routes.setting),
                    icon: const Icon(Icons.settings),
                  )
                : Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            context.push(Routes.events(userId: user.id)),
                        icon: const Icon(Icons.event_available_rounded),
                      ),
                      PopupMenuButton(
                        enabled: !networkActionState.isLoading,
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (BuildContext context) => [
                          if (user.networkStatus == NetworkStatus.CONNECTED)
                            PopupMenuItem(
                              value: 'unlink',
                              child: Text('Unlink'),
                            ),
                          if (user.networkStatus == NetworkStatus.PENDING)
                            PopupMenuItem(
                              value: 'cancel',
                              child: Text('Cancel Request'),
                            ),
                          PopupMenuItem(
                            value: 'report',
                            child: Text('Report User 🚩'),
                          ),
                        ],
                        onSelected: (value) async {
                          switch (value) {
                            case 'cancel':
                              await _performNetworkAction(
                                context: context,
                                ref: ref,
                                action: () => ref
                                    .read(
                                      networkActionProvider(user.id).notifier,
                                    )
                                    .cancelRequest(),
                                successMessage: 'Network request canceled',
                              );
                              break;
                            case 'unlink':
                              await _performNetworkAction(
                                context: context,
                                ref: ref,
                                action: () => ref
                                    .read(
                                      networkActionProvider(user.id).notifier,
                                    )
                                    .removeConnection(),
                                successMessage: 'Connection removed',
                              );
                              break;
                            case 'block':
                              break;
                            case 'report':
                              _openUserReportSheet(context, ref);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.defaultSpace),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: Dimens.avatarLg,
                        backgroundImage: user.profilePicture != null
                            ? NetworkImage(user.profilePicture!)
                            : AssetImage(Assets.defaultAvatar),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withAlpha(30),
                      ),
                      const SizedBox(height: Dimens.sm),
                      Text(
                        "@${user.username}",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: Dimens.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (user.role != UserRole.INSTITUTION)
                          Text(
                            user.university,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        if (user.role != UserRole.INSTITUTION)
                          const SizedBox(height: Dimens.xs),
                        if (user.role != UserRole.INSTITUTION)
                          Text(
                            user.role == UserRole.STUDENT
                                ? user.student!.degree
                                : user.expert!.expertise,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: Dimens.sm),

                        GestureDetector(
                          onTap: () => _showBioDialog(context),
                          child: Text(
                            user.bio ?? 'No bio available',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: Dimens.md),
                        if (isMe) MyNetwork(),
                        if (!isMe) OthersNetwork(user: user),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.md),
        const Divider(height: 5),
        if (user.role == UserRole.STUDENT && user.student?.interests != null)
          const SizedBox(height: Dimens.md),
        if (user.role == UserRole.STUDENT && user.student?.interests != null)
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Interests',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (user.role == UserRole.STUDENT && user.student?.interests != null)
          const SizedBox(height: Dimens.sm),
        if (user.role == UserRole.STUDENT && user.student?.interests != null)
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: Dimens.sm,
                runSpacing: Dimens.sm,
                children: List.generate(user.student!.interests!.length, (
                  index,
                ) {
                  return Chip(
                    label: Text(user.student!.interests![index]),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withAlpha(50),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimens.sm),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }

  void _showBioDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Bio",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // 🔥 Blur background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.transparent),
            ),

            // 🔥 Center popup
            Center(
              child: Material(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top row with ellipsis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Bio",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy'),
                              ),
                              const PopupMenuItem(
                                value: 'report',
                                child: Text('Report 🚩'),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'copy') {
                                Clipboard.setData(
                                  ClipboardData(text: user.bio ?? ''),
                                );
                              } else if (value == 'report') {
                                _openUserReportSheet(context, null);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Full bio (scrollable if long)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            user.bio ?? 'No bio available',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performNetworkAction({
    required BuildContext context,
    required WidgetRef ref,
    required Future<Result> Function() action,
    required String successMessage,
  }) async {
    final result = await action();
    result.fold(
      (_) {
        ref.invalidate(userProvider(user.id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      },
      (error, _) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      },
    );
  }

  void _openUserReportSheet(BuildContext context, WidgetRef? ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ReportSheet(
        title: 'Report User',
        onSubmit: (reason, message) {
          if (ref != null) {
            return ref
                .read(userReportActionProvider(user.id).notifier)
                .reportUser(reason: reason, message: message);
          }
          final container = ProviderScope.containerOf(context, listen: false);
          return container
              .read(userReportActionProvider(user.id).notifier)
              .reportUser(reason: reason, message: message);
        },
      ),
    );
  }
}
