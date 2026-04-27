import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniconnect/ui/profile/view_models/course_viewmodel_provider.dart';

import '../../config/assets.dart';
import '../../domain/models/course/course.dart';

class ExploreMentorshipScreen extends ConsumerWidget {
  const ExploreMentorshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCoursesAsync = ref.watch(topCoursesProvider);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
            'Explore Mentors', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader("Top Mentorship"),
            topCoursesAsync.when(
              loading: () =>
              const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.indigo),
              ),
              error: (err, st) => Center(child: Text("Connection Error: $err")),
              data: (result) {
                return result.fold(
                        (mentors) {
                      if (mentors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_motion_rounded,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                "The stage is empty",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                "No mentorships are currently active.",
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    ref.refresh(topCoursesProvider),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text("Refresh List"),
                                style: OutlinedButton.styleFrom(
                                  shape: StadiumBorder(),
                                  foregroundColor: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildMentorGrid(mentors);
                    }
                    , (error, stackTrace) =>
                    Center(child: Text("Error: $error"))
                );
              },
            ),
          ]
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildMentorGrid(List<
      (Course, String id, String fullName, String username, String? profileImage)> mentors) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: mentors.length,
      itemBuilder: (context, index) {
        final mentor = mentors[index];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: mentor.$5 != null
                      ? Image.network(mentor.$5!, fit: BoxFit.cover)
                      : Image.asset(Assets.defaultAvatar),
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor.$3,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        '@${mentor.$4}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => print('Tapped on ${mentor.$3}'),
                      splashColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}