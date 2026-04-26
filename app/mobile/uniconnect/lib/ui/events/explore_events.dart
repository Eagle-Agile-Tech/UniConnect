import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/domain/models/event/event.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_state_provider.dart';
import 'package:uniconnect/ui/setting/view_models/event_provider.dart';

import 'events_provider.dart';

class ExploreEventsScreen extends ConsumerWidget {
  const ExploreEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.value?.user?.id;
    if (userId == null || userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explore Events')),
        body: authState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          data: (_) => const Center(child: Text('User not found')),
        ),
      );
    }

    final uniEvents = ref.watch(
      allEventsProvider(authState.value!.user!.university),
    );
    final trendingEvents = ref.watch(trendingEventsProvider);
    final recent = ref.watch(allEventsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Events')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allEventsProvider(null));
          ref.invalidate(allEventsProvider(authState.value!.user!.university));
          ref.watch(trendingEventsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildSectionTitle('Trending'),
            trendingEvents.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              data: (events) {
                final now = DateTime.now();
                final upcoming =
                    events.where((event) => !event.ends.isBefore(now)).toList()
                      ..sort((a, b) => a.starts.compareTo(b.starts));
                return _buildEventList(
                  upcoming.take(10).toList(),
                  ref,
                  context,
                );
              },
            ),

            _buildSectionTitle('In Your Area'),
            uniEvents.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              data: (events) {
                return _buildEventList(
                  events.take(10).toList(),
                  ref,
                  context,
                );
              },
            ),

            _buildSectionTitle('Recent'),
            recent.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(error.toString())),
              data: (events) {
                return _buildEventList(
                  events.take(10).toList(),
                  ref,
                  context,
                );
              },
            ),
          ],
        ),
      ),
    );

    // return Scaffold(
    //   appBar: AppBar(title: const Text('Explore Events')),
    //   body: eventsAsync.when(
    //     loading: () => const Center(child: CircularProgressIndicator()),
    //     error: (error, stackTrace) => Center(child: Text(error.toString())),
    //     data: (events) {
    //       final now = DateTime.now();
    //       final upcoming =
    //           events.where((event) => !event.ends.isBefore(now)).toList()
    //             ..sort((a, b) => a.starts.compareTo(b.starts));
    //       final past =
    //           events.where((event) => event.ends.isBefore(now)).toList()
    //             ..sort((a, b) => b.starts.compareTo(a.starts));
    //       final popular = [...events]
    //         ..sort((a, b) => b.view.compareTo(a.view));
    //
    //       return RefreshIndicator(
    //         onRefresh: () async {
    //           ref.invalidate(eventProvider(userId));
    //           await ref.read(eventProvider(userId).future);
    //         },
    //         child: ListView(
    //           padding: const EdgeInsets.symmetric(vertical: 16),
    //           children: [
    //             _buildSectionTitle('Trending'),
    //             _buildEventList(upcoming.take(10).toList(), ref, context),
    //             const SizedBox(height: 20),
    //             _buildSectionTitle('Popular In Your University'),
    //             _buildEventList(popular.take(10).toList(), ref, context),
    //             const SizedBox(height: 20),
    //             _buildSectionTitle('Recent'),
    //             _buildEventList(past.take(10).toList(), ref, context),
    //           ],
    //         ),
    //       );
    //     },
    //   ),
    // );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEventList(
    List<Event> events,
    WidgetRef ref,
    BuildContext context,
  ) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          'No events available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildEventCard(events[index], ref, context),
      ),
    );
  }

  Widget _buildEventCard(Event event, WidgetRef ref, BuildContext context) {
    return InkWell(
      onTap: () {
        ref.read(selectedEventProvider.notifier).state = event;
        context.push(Routes.detailEventsScreen);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              spreadRadius: 2,
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.event, size: 40, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${DateFormat.MMMd().format(event.eventDay)} • ${event.location}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
