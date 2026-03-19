import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_screen.dart';
import 'package:uniconnect/ui/auth/onboarding/academic_profile/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/personalization/create_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/verify_email_screen.dart';
import 'package:uniconnect/ui/message/message_screen.dart';
import 'package:uniconnect/ui/post/create_post.dart';
import 'package:uniconnect/ui/setting/saved_screen.dart';
import 'package:uniconnect/utils/navigation_wrapper.dart';

import '../ui/community/community_form.dart';
import '../ui/community/community_screen.dart';
import '../ui/community/explore_community.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/search/search_screen.dart';
import '../ui/setting/setting_screen.dart';

final router = GoRouter(
  initialLocation: Routes.home,
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
    GoRoute(
      path: Routes.setting,
      builder: (context, state) => const SettingScreen(),
    ),
    GoRoute(
      path: Routes.saved,
      builder: (context, state) => const SavedScreen(),
    ),
    GoRoute(
      path: Routes.post,
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: Routes.createCommunity,
      builder: (context, state) => const CreateCommunityScreen(),
    ),
    GoRoute(
      path: Routes.communities,
      builder: (context, state) => const ExploreCommunityScreen(),
    ),

    GoRoute(
      path: Routes.userProfilePath,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: Routes.communityScreen,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CommunityScreen(communityId: id);
      },
    ),
  ],
);
