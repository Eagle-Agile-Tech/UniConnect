import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          'accessTokenExpiresIn': 50000,
          'accessTokenIssuedAt': 50000,
        }),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/verify-id',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/login',
        (server) =>
        server.reply(200,
        //     {
        //   'accessToken': 'jka',
        //   'refreshToken': 'jka',
        //   'accessTokenExpiresIn': 50000,
        //   'accessTokenIssuedAt': 50000,
        //   "id": "123",
        //   "firstName": "Daniel",
        //   "lastName": "Tesfaye",
        //   "role": "STUDENT",
        //   "email": "daniel.tesfaye@example.com",
        //   "username": "daniel_t",
        //   "university": "Jimma University",
        //   "networkCount": 101125,
        //   "bio": "Passionate about mobile app development and AI.",
        //   "profilePicture":
        //   "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
        //   "networkStatus": "CONNECTED",
        //   "STUDENT": {
        //     "currentYear": "3",
        //     "degree": "BSc Computer Science",
        //     "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
        //     "interests": ["Flutter", "Machine Learning", "Open Source"],
        //     "verificationStatus": "APPROVED",
        //   },
        // }

            {
              'accessToken': 'jka',
              'refreshToken': 'jka',
              'accessTokenExpiresIn': 50000,
              'accessTokenIssuedAt': 50000,
              "id": "123",
              "firstName": "Jimma University",
              "lastName": "",
              "role": "INSTITUTION",
              "email": "jimmauniversity@ju.edu.et",
              "username": "jimma_university",
              "university": "Jimma University",
              "networkCount": 101125,
              "bio": "Passionate about mobile app development and AI.",
              "profilePicture":
              "https://upload.wikimedia.org/wikipedia/en/f/fe/Current_Logo_of_Jimma_University.png",
              "INSTITUTION": {
                "type": "UNIVERSITY",
                "website": "https://ju.edu.et/",
                'verificationStatus': 'VERIFIED',
                "secretCode": "100290",
                "affiliatedExperts": [
                  {
                    // 'accessToken': 'jka',
                    // 'refreshToken': 'jka',
                    // 'accessTokenExpiresIn': 50000,
                    // 'accessTokenIssuedAt': 50000,
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
                    "networkStatus": "CONNECTED",
                    "STUDENT": {
                      "currentYear": "3",
                      "degree": "BSc Computer Science",
                      "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
                      "interests": [
                        "Flutter",
                        "Machine Learning",
                        "Open Source"
                      ],
                      "verificationStatus": "APPROVED",
                    },
                  },
                  {
                    // 'accessToken': 'jka',
                    // 'refreshToken': 'jka',
                    // 'accessTokenExpiresIn': 50000,
                    // 'accessTokenIssuedAt': 50000,
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
                    "networkStatus": "CONNECTED",
                    "STUDENT": {
                      "currentYear": "3",
                      "degree": "BSc Computer Science",
                      "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
                      "interests": [
                        "Flutter",
                        "Machine Learning",
                        "Open Source"
                      ],
                      "verificationStatus": "APPROVED",
                    },
                  }
                ],
              },
            }
        ),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/available/username/feisel',
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
          "EXPERT": {'expertise': 'Psychology', 'honor': 'Professor'},
        }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/profile/123',
        (server) =>
        server.reply(200, {
          "id": "123",
          'role': 'EXPERT',
          "firstName": "Charlotte",
          "lastName": "Anderson",
          "networkStatus": "CONNECTED",
          "email": "charlotte.a@example.com",
          "username": "charlotte",
          "university": "University of Edinburgh",
          "bio": "Tech blogger.",
          "profilePicture": "https://i.pravatar.cc/300?img=5",
          "accessToken": 'hello',
          "refreshToken": 'hello',
          "networkCount": 0,
          "EXPERT": {'expertise': 'Psychology', 'honor': 'Professor'},
        }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/profile/u_002',
        (server) =>
        server.reply(200, {
          "id": "u_002",
          "firstName": "Sara",
          "lastName": "Bekele",
          "role": "STUDENT",
          "email": "sara.bekele@example.com",
          "username": "sarab",
          "university": "Jimma University",
          "networkCount": 85,
          "bio": "Frontend enthusiast and UI/UX lover.",
          "profilePicture":
          "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
          "networkStatus": "PENDING",
          "STUDENT": {
            "currentYear": "2",
            "degree": "Software Engineering",
            "expectedGraduationYear": "2028-07-01T00:00:00.000Z",
            "interests": ["UI Design", "Flutter", "Figma"],
            "verificationStatus": "APPROVED",
          },
        }),
  );

  dioAdapter.onGet(
    '/users/available/username/ffff',
        (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/posts/fetch/u_002',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "u_002",
            "authorName": "Sara Bekele",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "tags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": true,
          },
        ]),
  );

  dioAdapter.onGet(
    RegExp(r'/searchPosts/.*'),
        (server) =>
        server.reply(200, [
      {
        "id": "p_001",
        "content": "Just finished my first Flutter app! Check out this UI.",
        "authorId": "123",
        "authorName": "Daniel Tesfaye",
        "authorProfilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
        "mediaUrls": ["https://images.unsplash.com/photo-1551650975-87deedd944c3"],
        "createdAt": "2026-03-05T10:00:00.000Z",
        "tags": ["Flutter", "MobileDev"],
        "likeCount": 42,
        "commentCount": 8,
        "isLikedByMe": true,
        "isBookmarkedByMe": false,
      },
      {
        "id": "p_002",
        "content": "Does anyone have resources for advanced Flutter or Python?",
        "authorId": "u_002",
        "authorName": "Sara Bekele",
        "authorProfilePicture": "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
        "mediaUrls": [],
        "createdAt": "2026-03-05T11:15:00.000Z",
        "tags": ["ML", "Python", "Help"],
        "likeCount": 12,
        "commentCount": 15,
        "isLikedByMe": false,
        "isBookmarkedByMe": true,
      },
      {
        "id": "p_003",
        "content": "The library is so quiet today. Perfect for grinding on the thesis. #Flutter",
        "authorId": "u_003",
        "authorName": "Abel Kebede",
        "authorProfilePicture": "https://i.pravatar.cc/300?img=12",
        "mediaUrls": ["https://images.unsplash.com/photo-1497633762265-9d179a990aa6"],
        "createdAt": "2026-03-05T09:30:00.000Z",
        "tags": ["Study", "CampusLife"],
        "likeCount": 89,
        "commentCount": 3,
        "isLikedByMe": false,
        "isBookmarkedByMe": false,
      },
        ]),
  );

  dioAdapter.onGet(
    '/posts/fetch/123',
        (server) =>
        server.reply(200, [
          {
            "id": "1",
            "content": "Just had an amazing day exploring the campus!",
            "authorId": "u_002",
            "authorName": "Sara Bekele",
            "authorProfilePicture":
            "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "tags": ["Flutter", "UI"],
            "likeCount": 24,
            "commentCount": 5,
            "isLikedByMe": false,
            "isBookmarkedByMe": true,
          },
        ]),
  );

  dioAdapter.onGet(
    '/v1/posts/feed/123',
        (server) =>
        server.reply(200, [
          {
            "id": "113",
            "content": "Campus vibes all around, buzzing with energy and life. Students moving between classes, each with their own story. Laughter echoes Campus vibes all around, buzzing with energy and life. Students moving between classes, each with their own story. Laughter echoes",
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
            "content": "Campus vibes all around, buzzing with energy and life. Students moving between classes, each with their own story. Laughter echoes",
            "authorId": "123",
            "authorName": "Daniel Tesfaye",
            "authorProfilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "tags": ["Flutter", "UI"],
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
              "firstName": "Sara",
              "lastName": "Bekele",
              "role": "STUDENT",
              "email": "sara.bekele@example.com",
              "username": "sarab",
              "university": "Jimma University",
              "networkCount": 85,
              "bio": "Frontend enthusiast and UI/UX lover.",
              "profilePicture":
              "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
              "networkStatus": "CONNECTED",
              "STUDENT": {
                "currentYear": "2",
                "degree": "Software Engineering",
                "expectedGraduationYear": "2028-07-01T00:00:00.000Z",
                "interests": ["UI Design", "Flutter", "Figma"],
                "verificationStatus": "APPROVED",
              },
            },
            {
              "id": "u_006",
              'role': 'EXPERT',
              "firstName": "Charlotte",
              "lastName": "Anderson",
              "email": "charlotte.a@example.com",
              "networkCount": 1200,
              "username": "charlotte",
              "university": "University of Edinburgh",
              "bio": "Tech blogger.",
              "profilePicture": "https://i.pravatar.cc/300?img=5",
              "networkStatus": "CONNECTED",
              "accessToken": 'hello',
              "refreshToken": 'hello',
              "EXPERT": {'expertise': 'Psychology', 'honor': 'Professor'},
            }
          ])
  );

  dioAdapter.onGet(
    RegExp(r'/users/profiles/username/.*'),
        (server) =>
        server.reply(200, [
          {
            "userId": "123",
            "username": "daniel_t",
            "profileImage": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
            "fullName": "Daniel Tesfaye"
          },
          {
            "userId": "u_002",
            "username": "daniel",
            "profileImage": "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
            "fullName": "Daniel Bekele"
          },
          {
            "userId": "u_003",
            "username": "dan_bel",
            "profileImage": "https://i.pravatar.cc/300?img=12",
            "fullName": "Daniel Kebede"
          },
          {
            "userId": "u_004",
            "username": "dannnel",
            "profileImage": "https://i.pravatar.cc/300?img=5",
            "fullName": "Marta Daniel"
          },
          {
            "userId": "u_005",
            "username": "dan_dyre",
            "profileImage": "https://i.pravatar.cc/300?img=3",
            "fullName": "Samuel Worku"
          },
        ]),
  );

  dioAdapter.onPost('/posts/createPost/', (server) => server.reply(200, {}));

  dioAdapter.onGet(
    '/v1/posts/comments/:1',
        (server) =>
        server.reply(200, [
      {
            "id": "1",
            "postId": "1",
            "content": "Butterflies are winged insects...",
            "authorId": "123",
            "authorName": "Daniel Tesfaye",
            "createdAt": DateTime.now().toIso8601String(),
            "likeCount": 10,
          },
        ]),
  );

  dioAdapter.onPost(
    'v1/posts/commentPost/:1',
        (server) => server.reply(200, {}),
  );

  dioAdapter.onPost('/v1/posts/bookmarkPost/:1', (server) => server.reply(200, {}));

  dioAdapter.onGet('/bookmarks/', (server) => server.reply(200, []));

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
    '/createCommunity',
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
            "authorName": "Daniel Tesfaye",
            "authorProfilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
            "mediaUrls": [
              "https://images.unsplash.com/photo-1518770660439-4636190af475",
            ],
            "createdAt": "2026-03-04T08:30:00.000Z",
            "tags": ["Flutter", "UI"],
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
    (server) => server.reply(
      200,
      [
        {
          'id': 'c1',
          "communityName": "Flutter Developers Hub",
          "ownerId": "u_101",
          "description":
              "A community for Flutter developers to share knowledge, ask questions, and collaborate on projects.",
          "profilePicture":
              "https://images.unsplash.com/photo-1555066931-4365d14bab8c",
          "members": 1200,
          "university": "Addis Ababa University",
        },
        {
          'id': 'c2',
          "communityName": "UI/UX Design Enthusiasts",
          "ownerId": "u_102",
          "description":
              "Exploring modern design trends, prototyping, and user-centric mobile interfaces.",
          "profilePicture":
              "https://images.unsplash.com/photo-1558655146-d09347e92766",
          "members": 850,
          "university": "Jimma University",
        },
        {
          'id': 'c3',
          "communityName": "AI & ML Ethiopia",
          "ownerId": "u_103",
          "description":
              "A hub for students interested in Artificial Intelligence and Machine Learning applications.",
          "profilePicture":
              "https://images.unsplash.com/photo-1677442136019-21780ecad995",
          "members": 640,
          "university": "Addis Ababa University",
        },
        {
          'id': 'c4',
          "communityName": "Startup Founders Network",
          "ownerId": "u_104",
          "description":
              "Connecting aspiring entrepreneurs and innovators across Ethiopian universities.",
          "profilePicture":
              "https://images.unsplash.com/photo-1556761175-b413da4baf72",
          "members": 2100,
          "university": "Haramaya University",
        },
        {
          'id': 'c5',
          "communityName": "Competitive Programming Club",
          "ownerId": "u_105",
          "description":
              "Solving complex algorithmic challenges and preparing for global coding competitions.",
          "profilePicture":
              "https://images.unsplash.com/photo-1515879218367-8466d910aaa4",
          "members": 420,
          "university": "Bahir Dar University",
        },
      ],
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

  // Missing endpoints
  dioAdapter.onGet(
    '/users/profile',
    (server) => server.reply(200, {
      "id": "123",
      "firstName": "Daniel",
      "lastName": "Tesfaye",
      "role": "STUDENT",
      "email": "daniel.tesfaye@example.com",
      "username": "daniel_t",
      "university": "Jimma University",
      "networkCount": 101125,
      "bio": "Passionate about mobile app development and AI.",
      "profilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
      "networkStatus": "CONNECTED",
      "STUDENT": {
        "currentYear": "3",
        "degree": "BSc Computer Science",
        "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
        "interests": ["Flutter", "Machine Learning", "Open Source"],
        "verificationStatus": "APPROVED",
      },
    }),
  );

  dioAdapter.onPatch(
    '/experts/profile',
    (server) => server.reply(200, {
      "id": "u_006",
      "role": "EXPERT",
      "firstName": "Charlotte",
      "lastName": "Anderson",
      "username": "charlotte",
      "networkStatus": "CONNECTED",
      "EXPERT": {'expertise': 'Psychology', 'honor': 'Professor'},
    }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/getFriends/',
    (server) => server.reply(200, [
      {
        "id": "u_001",
        "firstName": "Daniel",
        "lastName": "Tesfaye",
        "email": "daniel.tesfaye@example.com",
        "username": "daniel_t",
        "university": "Jimma University",
        "networkCount": 101,
        "role": "STUDENT",
        "profilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
        "networkStatus": "CONNECTED",
        "STUDENT": {
          "currentYear": "3",
          "degree": "BSc Computer Science",
          "expectedGraduationYear": "2027-07-10T00:00:00.000Z",
          "interests": ["Flutter", "Machine Learning"],
          "verificationStatus": "APPROVED"
        }
      },
      {
        "id": "u_002",
        "firstName": "Sara",
        "lastName": "Bekele",
        "email": "sara.bekele@example.com",
        "username": "sarab",
        "university": "Jimma University",
        "networkCount": 85,
        "role": "STUDENT",
        "profilePicture": "https://images.unsplash.com/photo-1495954484750-af469f2f9be5",
        "networkStatus": "CONNECTED",
        "STUDENT": {
          "currentYear": "2",
          "degree": "Software Engineering",
          "expectedGraduationYear": "2028-07-01T00:00:00.000Z",
          "interests": ["UI Design", "Flutter"],
          "verificationStatus": "APPROVED"
        }
      },
      {
        "id": "u_003",
        "firstName": "Abel",
        "lastName": "Kebede",
        "email": "abel.k@example.com",
        "username": "abelk",
        "university": "Addis Ababa University",
        "networkCount": 50,
        "role": "STUDENT",
        "profilePicture": "https://i.pravatar.cc/300?img=12",
        "networkStatus": "CONNECTED",
        "STUDENT": {
          "currentYear": "4",
          "degree": "Electrical Engineering",
          "expectedGraduationYear": "2026-06-30T00:00:00.000Z",
          "interests": ["Robotics", "IoT"],
          "verificationStatus": "APPROVED"
        }
      },
      {
        "id": "u_004",
        "firstName": "Marta",
        "lastName": "Daniel",
        "email": "marta.d@example.com",
        "username": "martad",
        "university": "Haramaya University",
        "networkCount": 120,
        "role": "STUDENT",
        "profilePicture": "https://i.pravatar.cc/300?img=5",
        "networkStatus": "CONNECTED",
        "STUDENT": {
          "currentYear": "1",
          "degree": "Medicine",
          "expectedGraduationYear": "2031-07-10T00:00:00.000Z",
          "interests": ["HealthTech", "Biology"],
          "verificationStatus": "APPROVED"
        }
      },
      {
        "id": "u_005",
        "firstName": "Samuel",
        "lastName": "Worku",
        "email": "samuel.w@example.com",
        "username": "samw",
        "university": "Bahir Dar University",
        "networkCount": 45,
        "role": "STUDENT",
        "profilePicture": "https://i.pravatar.cc/300?img=3",
        "networkStatus": "CONNECTED",
        "STUDENT": {
          "currentYear": "3",
          "degree": "Architecture",
          "expectedGraduationYear": "2027-08-15T00:00:00.000Z",
          "interests": ["Design", "Sustainability"],
          "verificationStatus": "APPROVED"
        }
      }
    ]),
  );

  dioAdapter.onPost(
    '/updateProfile/',
    (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/communityMembers/123',
    (server) => server.reply(200, [
      {
        "id": "u_001",
        "firstName": "Daniel",
        "lastName": "Tesfaye",
        "profilePicture": "https://images.unsplash.com/photo-1541698444083-023c97d3f4b6",
        "networkStatus": "CONNECTED",
      }
    ]),
  );

  dioAdapter.onGet(
    '/chats/u_002',
    (server) => server.reply(200, {'id': 'chat_001'}),
  );

  dioAdapter.onPost(
    '/v1/posts/likePost/:1',
    (server) => server.reply(200, {'likeCount': 25}),
  );
  WidgetsFlutterBinding.ensureInitialized();

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
