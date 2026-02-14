import 'dart:collection';
import 'package:flutter/material.dart';

typedef University = DropdownMenuEntry<String>;
typedef Interest = DropdownMenuEntry<String>;

abstract final class UCDummyData {
  static const List<String> universities = [
    "University of Oxford",
    "Massachusetts Institute of Technology (MIT)",
    "Stanford University",
    "Carnegie Mellon University",
    "ETH Zurich",
    "CODE University of Applied Sciences",
    "IT University of Copenhagen",
    "University of California, Berkeley",
    "University of California, Santa Cruz",
    "Frankfurt University of Applied Sciences",
  ];

  static final List<String> studentInterests = [
    "Technology & Programming",
    "Artificial Intelligence / Machine Learning",
    "Mobile App Development",
    "Web Development",
    "Data Science & Analytics",
    "Gaming & eSports",
    "Robotics & Engineering",
    "Photography & Videography",
    "Music & Instruments",
    "Sports & Fitness",
    "Travel & Adventure",
    "Reading & Writing",
    "Art & Design",
    "Fashion & Style",
    "Cooking & Baking",
    "Volunteering & Social Work",
    "Entrepreneurship & Startups",
    "Finance & Investment",
    "Environmental Awareness",
    "Meditation & Mindfulness",
    "Movies & TV Shows",
    "Anime & Comics",
    "Languages & Culture",
    "Debate & Public Speaking",
    "Photography & Blogging",
  ];

  static final List<University> universityEntries =
      UnmodifiableListView<University>(
        universities.map<University>(
          (university) => University(value: university, label: university),
        ),
      );

  static final List<Interest> interestEntries = UnmodifiableListView<Interest>(
    studentInterests.map<Interest>(
      (interest) => Interest(value: interest, label: interest),
    ),
  );
}
