import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uniconnect/data/repository/event/event_repository_remote.dart';
import 'package:uniconnect/ui/events/events_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_state_provider.dart';
import '../setting/view_models/event_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key});

  Future<void> _openMap(String location) async {
    final query = Uri.encodeComponent(location);
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayFormatter = DateFormat('EEEE, MMMM d');
    final event = ref.watch(selectedEventProvider);
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(child: Text('No event selected')),
      );
    }

    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .surface,
      appBar: AppBar(
        title: const Text('Event Details'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme
                    .of(
                  context,
                )
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 48,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timing Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeCard(
                          context,
                          label: "Date",
                          value: dayFormatter.format(event.eventDay),
                          icon: Icons.calendar_month,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeCard(
                          context,
                          label: "Duration",
                          value:
                          '${DateFormat('HH:mm').format(event
                              .starts)} - ${DateFormat('HH:mm').format(event
                              .ends)}',
                          icon: Icons.schedule,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location Card
                  _buildLocationCard(
                    context,
                    location:
                    event.location, // Assuming 'location' is in your model
                    onTap: () => _openMap(event.location),
                  ),

                  const SizedBox(height: 32),

                  // Description Section
                  Text(
                    "Description",
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      event.description,
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar
      bottomNavigationBar: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text("Done"),
                ),
              ),
            ),

            if (event.authorId ==
                ref.watch(authNotifierProvider).value?.user?.id)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(eventRepoProvider).deleteEvent(event.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Event deleted successfully"),
                        ),
                      );
                      context.pop();
                      ref.invalidate(eventProvider(event.authorId));
                    },
                    child: const Text("Delete"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme
            .of(context)
            .dividerColor),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme
              .of(context)
              .colorScheme
              .secondary),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, {
    required String location,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme
              .of(context)
              .dividerColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme
                  .of(context)
                  .colorScheme
                  .error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Location",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
