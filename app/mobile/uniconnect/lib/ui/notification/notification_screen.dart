import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';

import '../../config/assets.dart';
import '../../domain/models/notification/notification_item.dart';
import 'view_models/notification_viewmodel.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(notificationViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          notificationAsync.when(
            data: (state) => TextButton(
              onPressed: state.unreadCount == 0
                  ? null
                  : () => ref
                      .read(notificationViewModelProvider.notifier)
                      .markAllAsRead(),
              child: const Text('Mark all'),
            ),
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationViewModelProvider.notifier).refresh(),
        child: notificationAsync.when(
          data: (state) {
            if (state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 24),
                  ListTile(
                    title: Text('Network Requests'),
                  ),
                  SizedBox(
                    height: 320,
                    child: Center(child: Text('No notifications yet')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.items.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    title: const Text('Network Requests'),
                    trailing: IconButton(
                      onPressed: () => context.push(Routes.incomingNetworks),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  );
                }

                final item = state.items[index - 1];
                return ListTile(
                  tileColor: item.isRead
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.06),
                  onTap: () {
                    if (!item.isRead) {
                      ref
                          .read(notificationViewModelProvider.notifier)
                          .markAsRead(item.id);
                    }
                  },
                  leading: _buildAvatar(item),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _subtitle(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _relativeTime(item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            );
          },
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Network Requests'),
                trailing: IconButton(
                  onPressed: () => context.push(Routes.incomingNetworks),
                  icon: const Icon(Icons.chevron_right),
                ),
              ),
              SizedBox(
                height: 320,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text('Failed to load notifications: $error'),
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildAvatar(NotificationItem item) {
    final imageUrl = item.actor?.profileImage;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(imageUrl));
    }
    return const CircleAvatar(backgroundImage: AssetImage(Assets.defaultAvatar));
  }

  String _subtitle(NotificationItem item) {
    final actorName = item.actor?.displayName;
    if (actorName == null) {
      return item.body;
    }
    return '$actorName • ${item.body}';
  }

  String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
