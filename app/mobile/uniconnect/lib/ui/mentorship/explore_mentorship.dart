import 'package:flutter/material.dart';

class ExploreMentorshipScreen extends StatelessWidget {
  const ExploreMentorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Explore Mentors', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader("Featured Mentors"),
          _buildMentorGrid(featuredMentors),
          const SizedBox(height: 24),
          _buildSectionHeader("Design & Creative"),
          _buildMentorGrid(designMentors),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildMentorGrid(List<Map<String, String>> mentors) {
    return GridView.builder(
      shrinkWrap: true, // Necessary to use inside ListView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Max 2 in horizontal direction
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85, // Adjust for card height
      ),
      itemCount: mentors.length,
      itemBuilder: (context, index) {
        final mentor = mentors[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent,
                      child: Text(mentor['name']![0], style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mentor['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  mentor['course']!,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  mentor['duration']!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue[300]),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dummy Data
final featuredMentors = [
  {"name": "Sarah Jenkins", "course": "Advanced Flutter Architecture", "duration": "8 Weeks"},
  {"name": "Arjun Rao", "course": "Backend with Node.js", "duration": "6 Weeks"},
];

final designMentors = [
  {"name": "Leo V.", "course": "UI/UX Mastery", "duration": "10 Weeks"},
  {"name": "Elena Smith", "course": "Product Design 101", "duration": "4 Weeks"},
];