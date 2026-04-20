import 'package:flutter/material.dart';

class ExploreEventsScreen extends StatelessWidget {
  const ExploreEventsScreen({super.key});

  final List<Map<String, String>> trendingEvents = const [
    {'title': 'Tech Meetup', 'date': 'Apr 10', 'location': 'Online'},
    {'title': 'Music Fest', 'date': 'Apr 15', 'location': 'Campus Hall'},
    {'title': 'Art Workshop', 'date': 'Apr 20', 'location': 'Gallery Room'},
  ];

  final List<Map<String, String>> universityEvents = const [
    {'title': 'Lecture Series', 'date': 'Apr 12', 'location': 'Auditorium'},
    {'title': 'Hackathon', 'date': 'Apr 18', 'location': 'Lab 101'},
    {'title': 'Sports Day', 'date': 'Apr 25', 'location': 'Main Field'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Events'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Trending'),
            _buildEventList(trendingEvents),
            const SizedBox(height: 20),
            _buildSectionTitle('From Your University'),
            _buildEventList(universityEvents),
            const SizedBox(height: 20),
            _buildSectionTitle('Recommended for You'),
            _buildEventList(trendingEvents.reversed.toList()), // just demo
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEventList(List<Map<String, String>> events) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, String> event) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 6,
          )
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
              child: const Center(child: Icon(Icons.event, size: 40, color: Colors.white70)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${event['date']} • ${event['location']}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}