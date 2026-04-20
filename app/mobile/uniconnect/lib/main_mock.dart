import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniconnect/routing/router.dart';
import 'package:uniconnect/ui/core/theme/theme.dart';

import 'config/theme_provider.dart';
import 'data/service/api/api_client.dart';
import 'data/service/api/auth_api_client.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final dioAdapter = DioAdapter(dio: dio);


  dioAdapter.onPost(
    '/auth/register',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/verify-otp',
        (server) =>
        server.reply(200, {
          'university': 'Harvard University',
          'accessToken': 'jka',
          'refreshToken': 'jka',
        }),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/verifyID',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/login',
        (server) =>
        server.reply(200, {
          'accessToken': 'jka',
          'refreshToken': 'jka',
          "id": "123",
          "firstName": "Daniel",
          "lastName": "Tesfaye",
          "role": "STUDENT",
          "email": "daniel.tesfaye@example.com",
          "username": "daniel_t",
          "university": "Jimma University",
          "networkCount": 101125,
          "bio": "Passionate about mobile app development and AI.",
          "profilePicture":
          "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
          "areWe": true,
          "student": {
            "currentYear": "3",
            "degree": "BSc Computer Science",
            "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
            "interests": ["Flutter", "Machine Learning", "Open Source"],
            "verificationStatus": "APPROVED",
          },
        }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/username/feisel/available',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/users/profile',
        (server) =>
        server.reply(200, {
          "id": "123",
          'role': 'EXPERT',
          "firstName": "Charlotte",
          "lastName": "Anderson",
          "email": "charlotte.a@example.com",
          "username": "charlotte",
          "university": "University of Edinburgh",
          "bio": "Tech blogger.",
          "profilePicture": "https://i.pravatar.cc/300?img=5",
          "accessToken": 'hello',
          "refreshToken": 'hello',
          "networkCount": 0,
          "expert": {'expertise': 'Psychology', 'honor': 'Professor'},
        }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/getUser/u_002',
        (server) =>
        server.reply(200, {
          "id": "u_002",
          "firstName": "Daniel",
          "lastName": "Tesfaye",
          "role": "STUDENT",
          "email": "daniel.tesfaye@example.com",
          "username": "daniel_t",
          "university": "Jimma University",
          "networkCount": 101125,
          "bio": "Passionate about mobile app development and AI.",
          "profilePicture":
          "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
          "areWe": true,
          "student": {
            "currentYear": "3",
            "degree": "BSc Computer Science",
            "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
            "interests": ["Flutter", "Machine Learning", "Open Source"],
            "verificationStatus": "APPROVED",
          },
        }),
  );

  dioAdapter.onGet(
    '/users/username/ffff/available',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/posts/u_002',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "123",
            "authorName": "John Doe",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "hashtags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": true,
          },
        ]),
  );

  dioAdapter.onGet(
    '/searchPosts/iman',
        (server) =>
        server.reply(200, [
      {
        "id": "p_001",
        "content": "Just finished my first Flutter app! Check out this UI.",
        "authorId": "u_001",
        "authorName": "Daniel Tesfaye",
        "authorProfilePicture": "https://images.unsplash.com/photo-1518770660439-4636190af475",
        "mediaUrls": ["https://images.unsplash.com/photo-1551650975-87deedd944c3"],
        "createdAt": "2026-03-05T10:00:00.000Z",
        "hashtags": ["Flutter", "MobileDev"],
        "likeCount": 42,
        "commentCount": 8,
        "isLikedByMe": true,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_002",
        "content": "Does anyone have resources for advanced Machine Learning in Python?",
        "authorId": "u_002",
        "authorName": "Sara Bekele",
        "authorProfilePicture": "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
        "mediaUrls": [],
        "createdAt": "2026-03-05T11:15:00.000Z",
        "hashtags": ["ML", "Python", "Help"],
        "likeCount": 12,
        "commentCount": 15,
        "isLikedByMe": false,
        "isBookmarkedByMe": true,
      },
      {
        "id": "p_003",
        "content": "The library is so quiet today. Perfect for grinding on the thesis.",
        "authorId": "u_003",
        "authorName": "Abel Kebede",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=12",
        "mediaUrls": ["https://images.unsplash.com/photo-1497633762265-9d179a990aa6"],
        "createdAt": "2026-03-05T09:30:00.000Z",
        "hashtags": ["Study", "CampusLife"],
        "likeCount": 89,
        "commentCount": 3,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_004",
        "content": "New Research Paper Published: 'Robotics in Agriculture'. Link in bio!",
        "authorId": "u_004",
        "authorName": "Marta Hailu",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=5",
        "mediaUrls": [],
        "createdAt": "2026-03-04T15:45:00.000Z",
        "hashtags": ["Research", "Robotics"],
        "likeCount": 156,
        "commentCount": 24,
        "isLikedByMe": true,
        "isBookmarkedByMe": true,
      },
      {
        "id": "p_005",
        "content": "Searching for Flutter mentors to help with a startup project!",
        "authorId": "u_005",
        "authorName": "Samuel Worku",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=3",
        "mediaUrls": [],
        "createdAt": "2026-03-04T08:30:00.000Z",
        "hashtags": ["Mentorship", "Startups"],
        "likeCount": 5,
        "commentCount": 1,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_006",
        "content": "Who's attending the Hackathon this weekend? Team 'CodeRangers' is looking for a designer!",
        "authorId": "123",
        "authorName": "John Doe",
        "authorProfilePicture": "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d",
        "mediaUrls": ["https://images.unsplash.com/photo-1504384308090-c894fdcc538d"],
        "createdAt": "2026-03-05T14:20:00.000Z",
        "hashtags": ["Hackathon", "UIUX"],
        "likeCount": 34,
        "commentCount": 12,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_007",
        "content": "Sunrise at Jimma University. Best way to start the day.",
        "authorId": "u_002",
        "authorName": "Sara Bekele",
        "authorProfilePicture": "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
        "mediaUrls": ["https://images.unsplash.com/photo-1470252649358-96949c751bd8"],
        "createdAt": "2026-03-05T06:10:00.000Z",
        "hashtags": ["Morning", "Campus"],
        "likeCount": 210,
        "commentCount": 9,
        "isLikedByMe": true,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_008",
        "content": "Just a reminder: Midterm results are out for CS302.",
        "authorId": "u_004",
        "authorName": "Marta Hailu",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=5",
        "mediaUrls": [],
        "createdAt": "2026-03-03T16:00:00.000Z",
        "hashtags": ["CS302", "Grades"],
        "likeCount": 22,
        "commentCount": 45,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_009",
        "content": "Exploring the integration of AI in everyday mobile apps. Any thoughts?",
        "authorId": "u_001",
        "authorName": "Daniel Tesfaye",
        "authorProfilePicture": "https://images.unsplash.com/photo-1518770660439-4636190af475",
        "mediaUrls": [],
        "createdAt": "2026-03-02T12:00:00.000Z",
        "hashtags": ["AI", "Innovation"],
        "likeCount": 67,
        "commentCount": 14,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_010",
        "content": "Weekend coding session! Coffee and Dart.",
        "authorId": "u_003",
        "authorName": "Abel Kebede",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=12",
        "mediaUrls": ["https://images.unsplash.com/photo-1499750310107-5fef28a66643"],
        "createdAt": "2026-03-01T20:30:00.000Z",
        "hashtags": ["Coding", "Dart"],
        "likeCount": 45,
        "commentCount": 2,
        "isLikedByMe": false,
        "isBookmarkedByMe": true,
      },
        ]),
  );

  dioAdapter.onGet(
    '/posts/123',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "123",
            "authorName": "John Doe",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "hashtags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": true,
          },
        ]),
  );

  dioAdapter.onGet(
    '/feed/',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Campus vibes!",
            "authorId": "u_002",
            "authorName": "Sara Bekele",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
            "createdAt": "2026-03-04T08:30:00.000Z",
            "likeCount": 12,
            "commentCount": 2,
            "isLikedByMe": true,
            "isBookmarkedByMe": false,
          },
          {
            "id": "2",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "123",
            "authorName": "John Doe",
            "authorProfilePicture": null,
            "mediaUrls": [
              "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "hashtags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": false,
          },
        ]),
  );

  dioAdapter.onGet(
      '/networks/u_002',
          (server) =>
          server.reply(200, [
            {
              "id": "u_002",
              "firstName": "Alemseged",
              "lastName": "Solomon",
              "role": "STUDENT",
              "email": "daniel.tesfaye@example.com",
              "username": "daniel_t",
              "university": "Jimma University",
              "networkCount": 101125,
              "bio": "Passionate about mobile app development and AI.",
              "profilePicture":
              "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
              "areWe": true,
              "student": {
                "currentYear": "3",
                "department": "BSc Computer Science",
                "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
                "interests": ["Flutter", "Machine Learning", "Open Source"],
                "verificationStatus": "APPROVED",
              },
            },
            {
              "id": "u_002",
              'role': 'EXPERT',
              "firstName": "Marsilas",
              "lastName": "Demeke",
              "email": "charlotte.a@example.com",
              "networkCount": 100080009000,
              "username": "charlotte",
              "university": "University of Edinburgh",
              "bio": "Tech blogger.",
              "profilePicture": "https://i.pravatar.cc/300?img=5",
              "accessToken": 'hello',
              "refreshToken": 'hello',
              "expert": {'expertise': 'Psychology', 'honor': 'Professor'},
            }
          ])
  );

  dioAdapter.onGet(
    '/searchUsers/iman',
        (server) =>
        server.reply(200, [
          {
            "id": "u_001",
            "role": "STUDENT",
            "firstName": "Daniel",
            "lastName": "Tesfaye",
            "email": "daniel.tesfaye@example.com",
            "username": "danites",
            "university": "Addis Ababa University",
            "networkCount": 120,
            "bio": "Passionate about mobile development and AI.",
            "profilePicture": "https://images.unsplash.com/photo-1518770660439-4636190af475",
            "student": {
              "currentYear": "3",
              "degree": "Computer Science",
              "expectedGraduationYear": "2027-07-15T00:00:00Z",
              "interests": ["Flutter", "Machine Learning", "Startups"],
              "verificationStatus": "APPROVED"
            }
          },
          {
            "id": "u_002",
            "role": "STUDENT",
            "firstName": "Sara",
            "lastName": "Bekele",
            "email": "sara.bekele@example.com",
            "username": "sarab",
            "university": "Jimma University",
            "networkCount": 85,
            "bio": "Frontend enthusiast and UI/UX lover.",
            "profilePicture": "https://example.com/profiles/u_002.jpg",
            "student": {
              "currentYear": "2",
              "degree": "Software Engineering",
              "expectedGraduationYear": "2028-07-01T00:00:00Z",
              "interests": ["UI Design", "Flutter", "Figma"],
              "verificationStatus": "APPROVED"
            }
          },
          {
            "id": "u_003",
            "role": "EXPERT",
            "firstName": "Abel",
            "lastName": "Kebede",
            "email": "abel.kebede@example.com",
            "username": "abelk",
            "university": "Bahir Dar University",
            "networkCount": 450,
            "bio": "Interested in backend systems and cloud computing.",
            "profilePicture": "https://i.pravatar.cc/300?img=12",
            "expert": {
              "expertise": "Cloud Computing",
              "honor": "Senior Architect"
            }
          },
          {
            "id": "u_004",
            "role": "EXPERT",
            "firstName": "Marta",
            "lastName": "Hailu",
            "email": "marta.hailu@example.com",
            "username": "martah",
            "university": "Hawassa University",
            "networkCount": 320,
            "bio": "Embedded systems specialist.",
            "profilePicture": "https://example.com/profiles/u_004.jpg",
            "expert": {
              "expertise": "Robotics",
              "honor": "Lead Researcher"
            }
          },
          {
            "id": "u_005",
            "role": "EXPERT",
            "firstName": "Samuel",
            "lastName": "Worku",
            "email": "samuel.worku@example.com",
            "username": "samworku",
            "university": "Adama Science and Technology University",
            "networkCount": 1200,
            "bio": "Data nerd who enjoys building ML models.",
            "profilePicture": "https://example.com/profiles/u_005.jpg",
            "expert": {
              "expertise": "Data Science",
              "honor": "Doctorate"
            }
          },
        ]),
  );

  dioAdapter.onPost('/createPost/123', (server) => server.reply(200, {}));

  dioAdapter.onGet(
    '/comments/1',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "postId": "1",
            "content": "Butterflies are winged insects...",
            "authorId": "123",
            "authorName": "John Doe",
            "createdAt": DateTime.now().toIso8601String(),
            "likeCount": 10,
          },
        ]),
  );

  dioAdapter.onPost(
    '/commentPost/1',
        (server) => server.reply(404, {'message': 'Not Found'}),
  );

  dioAdapter.onPost('/bookmarkPost/1', (server) => server.reply(200, {}));

  dioAdapter.onGet('/bookmarks/123', (server) => server.reply(200, []));

  dioAdapter.onGet('users/event/123', (server) => server.reply(200, [
    {
      "title": "Tech Meetup Addis",
      "description": "A meetup for developers to discuss Flutter and backend trends.",
      "starts": "2026-04-10T09:00:00.000Z",
      "ends": "2026-04-10T12:00:00.000Z",
      "authorId": "user_101",
      "eventDay": "2026-04-10T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "Startup Pitch Night",
      "description": "Local startups pitch their ideas to investors.",
      "starts": "2026-04-12T17:00:00.000Z",
      "ends": "2026-04-12T20:00:00.000Z",
      "authorId": "user_102",
      "eventDay": "2026-04-12T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "UI/UX Workshop",
      "description": "Hands-on workshop on designing modern mobile interfaces.",
      "starts": "2026-04-15T13:00:00.000Z",
      "ends": "2026-04-15T16:00:00.000Z",
      "authorId": "user_103",
      "eventDay": "2026-04-15T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "Hackathon 2026",
      "description": "24-hour coding challenge with prizes.",
      "starts": "2026-04-20T08:00:00.000Z",
      "ends": "2026-04-21T08:00:00.000Z",
      "authorId": "user_104",
      "eventDay": "2026-04-20T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"

    },
    {
      "title": "AI & Machine Learning Talk",
      "description": "Exploring practical AI applications in Africa.",
      "starts": "2026-04-25T10:00:00.000Z",
      "ends": "2026-04-25T12:30:00.000Z",
      "authorId": "user_105",
      "eventDay": "2026-04-25T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    }
  ]));

  dioAdapter.onGet('users/event/u_002', (server) => server.reply(200, [
    {
      "title": "Tech Meetup Addis",
      "description": "A meetup for developers to discuss Flutter and backend trends.",
      "starts": "2026-04-10T09:00:00.000Z",
      "ends": "2026-04-10T12:00:00.000Z",
      "authorId": "user_101",
      "eventDay": "2026-04-10T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "Startup Pitch Night",
      "description": "Local startups pitch their ideas to investors.",
      "starts": "2026-04-12T17:00:00.000Z",
      "ends": "2026-04-12T20:00:00.000Z",
      "authorId": "user_102",
      "eventDay": "2026-04-12T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "UI/UX Workshop",
      "description": "Hands-on workshop on designing modern mobile interfaces.",
      "starts": "2026-04-15T13:00:00.000Z",
      "ends": "2026-04-15T16:00:00.000Z",
      "authorId": "user_103",
      "eventDay": "2026-04-15T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    },
    {
      "title": "Hackathon 2026",
      "description": "24-hour coding challenge with prizes.",
      "starts": "2026-04-20T08:00:00.000Z",
      "ends": "2026-04-21T08:00:00.000Z",
      "authorId": "user_104",
      "eventDay": "2026-04-20T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"

    },
    {
      "title": "AI & Machine Learning Talk",
      "description": "Exploring practical AI applications in Africa.",
      "starts": "2026-04-25T10:00:00.000Z",
      "ends": "2026-04-25T12:30:00.000Z",
      "authorId": "user_105",
      "eventDay": "2026-04-25T00:00:00.000Z",
      "location": "Addis Ababa University | Natural Sciences Campus"
    }
  ]));

  // =========================
  // COMMUNITIES MOCKS
  // =========================
  dioAdapter.onPost(
    '/createCommunity/123',
        (server) =>
        server.reply(200, {
          'id': '123',
          'profileUrl':
          "https://images.unsplash.com/photo-1518770660439-4636190af475",
        }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/communityPosts/123',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Campus vibes!",
            "authorId": "u_002",
            "authorName": "Sara Bekele",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
            "createdAt": "2026-03-04T08:30:00.000Z",
            "likeCount": 12,
            "commentCount": 2,
            "isLikedByMe": true,
            "isBookmarkedByMe": false,
          },
          {
            "id": "2",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "123",
            "authorName": "John Doe",
            "authorProfilePicture": null, // Testing null safety
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "hashtags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": false,
          },
        ]),
  );

  dioAdapter.onGet(
    '/getCommunity/123',
        (server) =>
        server.reply(200, {
          'id': '123',
          "communityName": "Flutter Developers Hub",
          "ownerId": "5",
          "description":
          "A community for Flutter developers to share knowledge, ask questions, and collaborate on projects.",
          "profilePicture":
          "https://images.unsplash.com/photo-1555066931-4365d14bab8c",
          "members": 1000,
          'university': 'Jimma University',
          'isMember': true,
        }),
  );

  dioAdapter.onGet(
    '/topCommunities',
        (server) =>
        server.reply(
          200,
          List.generate(
            5,
                (index) =>
            {
              'id': '123',
              "communityName": "Flutter Developers Hub",
              "ownerId": "user_56789",
              "description":
              "A community for Flutter developers to share knowledge, ask questions, and collaborate on projects.",
              "profilePicture":
              "https://images.unsplash.com/photo-1555066931-4365d14bab8c",
              "members": 2000,
              "university": "Addis Ababa University",
            },
          ),
        ),
  );

  dioAdapter.onGet(
    '/courses/123',
        (server) =>
        server.reply(200, [
          {
            "id": "c1",
            "title": "Flutter for Beginners",
            "link": "https://example.com/flutter",
            "description": "Learn the basics of Flutter and build mobile apps.",
            "enrolled": 1200,
            "price": 49,
          },
          {
            "id": "c2",
            "title": "Advanced Dart Programming",
            "link": "https://example.com/dart",
            "description":
            "Deep dive into Dart language features and best practices.",
            "enrolled": 850,
            "price": 59,
          },
          {
            "id": "c3",
            "title": "Fullstack Web Development",
            "link": "https://example.com/fullstack",
            "description": "Build complete web apps using modern tools.",
            "enrolled": 2000,
            "price": 99,
          },
          {
            "id": "c4",
            "title": "Data Structures & Algorithms",
            "link": "https://example.com/dsa",
            "description": "Master DSA for coding interviews.",
            "enrolled": 1750,
            "price": 79,
          },
          {
            "id": "c5",
            "title": "UI/UX Design Fundamentals",
            "link": "https://example.com/uiux",
            "description":
            "Learn design principles and user experience strategies.",
            "enrolled": 940,
            "price": 39,
          },
        ]),
    data: Matchers.any,
  );

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWithValue(ApiClient(client: dio)),
        authApiProvider.overrideWithValue(AuthApiClient(client: dio)),
      ],
      child: const UniConnectMock(),
    ),
  );
}

class UniConnectMock extends ConsumerWidget {
  const UniConnectMock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: UCTheme.lightTheme,
      darkTheme: UCTheme.darkTheme,
      themeMode: themeState.value ?? ThemeMode.system,
    );
  }
}
