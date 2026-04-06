import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:uniconnect/routing/router.dart';
import 'package:uniconnect/ui/core/theme/theme.dart';

import 'data/service/api/api_client.dart';
import 'data/service/api/auth_api_client.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
  final dioAdapter = DioAdapter(dio: dio);

  // =========================
  // AUTHENTICATION MOCKS
  // =========================
  dioAdapter.onPost(
    '/auth/register',
    (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onPost(
    '/auth/verify-otp',
    (server) => server.reply(200, {
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
    (server) => server.reply(200, {
      "id": "123",
      'role': 'EXPERT',
      "firstName": "Charlotte",
      "lastName": "Anderson",
      "email": "charlotte.a@example.com",
      "username": "charlotte",
      "networkCount": 0,
      "university": "University of Edinburgh",
      "bio": "Tech blogger.",
      "profilePicture": "https://i.pravatar.cc/300?img=5",
      "accessToken": 'hello',
      "refreshToken": 'hello',
      "expert": {'expertise': 'Psychology', 'honor': 'Professor'},
    }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/username/feisel/available',
    (server) => server.reply(200, ''),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/users/profile',
    (server) => server.reply(200, {
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
    (server) => server.reply(200, {
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
        "department": "BSc Computer Science",
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
    (server) => server.reply(200, [
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
    '/posts/123',
    (server) => server.reply(200, [
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
    (server) => server.reply(200, [
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
      (server) => server.reply(200,[
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
    '/comments/1',
    (server) => server.reply(200, [
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

  // =========================
  // COMMUNITIES MOCKS
  // =========================
  dioAdapter.onPost(
    '/createCommunity/123',
    (server) => server.reply(200, {
      'id': '123',
      'profileUrl':
          "https://images.unsplash.com/photo-1518770660439-4636190af475",
    }),
    data: Matchers.any,
  );

  dioAdapter.onGet(
    '/getCommunity/123',
    (server) => server.reply(200, {
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
      List.generate(
        5,
        (index) => {
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
    (server) => server.reply(200, [
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

  runApp(
    ProviderScope(
      overrides: [
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
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: UCTheme.lightTheme,
      darkTheme: UCTheme.darkTheme,
    );
  }
}
