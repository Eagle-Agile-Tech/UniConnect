import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_screen.dart';
import 'package:uniconnect/ui/auth/onboarding/academic_profile/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/personalization/create_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/verify_email_screen.dart';
import 'package:uniconnect/ui/explore/explore_screen.dart';
import 'package:uniconnect/ui/message/message_screen.dart';
import 'package:uniconnect/ui/post/create_post.dart';
import 'package:uniconnect/utils/navigation_wrapper.dart';

import '../ui/search/search_screen.dart';

final router = GoRouter(
  initialLocation: Routes.loginOrSignup,
  debugLogDiagnostics: true,

  routes: [
    GoRoute(
      path: Routes.loginOrSignup,
      builder: (context, state) => const AuthScreen(),
    ),

    GoRoute(
      path: Routes.verifyEmail,
      builder: (context, state) => const VerifyEmailScreen(),
    ),

    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const AcademicProfile(),
      routes: [
        GoRoute(
          path: 'academic',
          builder: (context, state) => const AcademicProfile(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const CreateProfile(),
        ),
      ],
    ),

    GoRoute(
      path: Routes.home,
      builder: (context, state) => const NavigationWrapper(),
      routes: [
        GoRoute(
          path: 'createPost',
          builder: (context, state) => const CreatePostScreen(),
        ),
      ],
    ),

    GoRoute(
      path: Routes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: Routes.messaging,
      builder: (context, state) => const MessageScreen(),
    ),
  ],
);
