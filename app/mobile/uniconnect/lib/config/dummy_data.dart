import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:uniconnect/ui/core/theme/colors.dart';
import 'package:uniconnect/ui/core/theme/dimens.dart';

typedef UniversityRecord = ({String name, String acronomy});
typedef University = DropdownMenuEntry<UniversityRecord>;
typedef InterestRecord = ({String interest, String emoji});
typedef Interest = DropdownMenuEntry<InterestRecord>;

abstract final class UCDummyData {
  static const List<UniversityRecord> universities = [
    (name: 'Jimma University', acronomy: 'JU'),
    (name: 'University of Oxford', acronomy: 'OX'),
    (name: 'Massachusetts Institute of Technology', acronomy: 'MIT'),
    (name: 'Stanford University', acronomy: 'SU'),
    (name: 'Harvard University', acronomy: 'HU'),
    (name: 'California Institute of Technology', acronomy: 'Caltech'),
    (name: 'University of Cambridge', acronomy: 'UC'),
    (name: 'Princeton University', acronomy: 'PU'),
    (name: 'Yale University', acronomy: 'YU'),
  ];

  static final List<InterestRecord> studentInterests = [
    (interest: 'Technology & Programming', emoji: '\u{1F4BB}'),
    (
      interest: 'Artificial Intelligence / Machine Learning',
      emoji: '\u{1F9E0}',
    ),
    (interest: 'Mobile App Development', emoji: '\u{1F4F1}'),
    (interest: 'Web Development', emoji: '\u{1F310}'),
    (interest: 'Data Science & Analytics', emoji: '\u{1F4CA}'),
    (interest: 'Gaming & eSports', emoji: '\u{1F3AE}'),
    (interest: 'Robotics & Engineering', emoji: '\u{1F916}'),
    (interest: 'Photography & Videography', emoji: '\u{1F4F7}'),
    (interest: 'Music & Instruments', emoji: '\u{1F3B5}'),
    (interest: 'Sports & Fitness', emoji: '\u{1F3CB}\u{FE0F}'),
    (interest: 'Travel & Adventure', emoji: '\u{2708}\u{FE0F}'),
    (interest: 'Reading & Writing', emoji: '\u{1F4DA}'),
    (interest: 'Art & Design', emoji: '\u{1F3A8}'),
    (interest: 'Fashion & Style', emoji: '\u{1F457}'),
    (interest: 'Cooking & Baking', emoji: '\u{1F373}'),
    (interest: 'Volunteering & Social Work', emoji: '\u{1F91D}'),
    (interest: 'Entrepreneurship & Startups', emoji: '\u{1F680}'),
    (interest: 'Finance & Investment', emoji: '\u{1F4B0}'),
    (interest: 'Environmental Awareness', emoji: '\u{1F33F}'),
    (interest: 'Meditation & Mindfulness', emoji: '\u{1F9D8}'),
    (interest: 'Movies & TV Shows', emoji: '\u{1F3AC}'),
    (interest: 'Anime & Comics', emoji: '\u{1F5BC}\u{FE0F}'),
    (interest: 'Languages & Culture', emoji: '\u{1F5E3}\u{FE0F}'),
  ];

  static final List<University> universityEntries =
      UnmodifiableListView<University>(
        universities.map<University>(
          (university) => University(
            value: university,
            label: '${university.acronomy} ${university.name}',
            labelWidget: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimens.xs),
                  decoration: BoxDecoration(
                    color: UCColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    university.acronomy,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: Dimens.sm),
                Text(university.name),
              ],
            ),
          ),
        ),
      );

  static final List<Interest> interestEntries = UnmodifiableListView<Interest>(
    studentInterests.map<Interest>(
      (interest) => Interest(
        value: interest,
        label: interest.interest,
        labelWidget: Row(
          children: [
            Text(interest.interest),
            const SizedBox(width: Dimens.sm),
            Text(interest.emoji),
          ],
        ),
      ),
    ),
  );
}
