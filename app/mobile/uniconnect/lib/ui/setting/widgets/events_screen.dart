import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';
import 'package:uniconnect/ui/events/events_provider.dart';
import 'package:uniconnect/ui/setting/view_models/event_provider.dart';

import '../../../domain/models/event/event.dart';

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key, this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userID = userId ?? authState.value?.user?.id;
    if (userID == null || userID.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(
            userId != null ? 'Coming up' : 'My Events',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: authState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          data: (_) => const Center(child: Text('User not found')),
        ),
      );
    }

    final eventAsync = ref.watch(eventProvider(userID));

    Future<void> onRefresh() async {
      ref.invalidate(eventProvider(userID));
      await ref.read(eventProvider(userID).future);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          userId != null ? 'Coming up' : 'My Events',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (userId == null)
            IconButton(
              onPressed: () => context.push(Routes.addEvent),
              icon: Icon(
                Icons.add_circle_outline_outlined,
                size: Dimens.iconLg,
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.defaultSpace,
          0,
          Dimens.defaultSpace,
          Dimens.defaultSpace,
        ),
        child: eventAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.event_busy_outlined,
                      size: 52,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Center(child: Text('No events yet')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(events[index], context, ref);
                },
              ),
            );
          },
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString()),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(eventProvider(userID)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event, BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Indicator
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.eventDay.day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(event.eventDay),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Event Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '${DateFormat('HH:mm').format(event.starts)} - ${DateFormat('HH:mm').format(event.ends)}',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              ref.read(selectedEventProvider.notifier).state = event;
              context.push(Routes.detailEventsScreen);
            },
          ),
        ],
      ),
    );
  }
}
