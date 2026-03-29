import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_screen.dart';
import 'package:uniconnect/ui/auth/onboarding/academic_profile/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/personalization/create_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/verify_email_screen.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/signup/signup_screen.dart';
import 'package:uniconnect/ui/message/message_screen.dart';
import 'package:uniconnect/ui/post/create_post.dart';
import 'package:uniconnect/ui/setting/widgets/saved_screen.dart';
import 'package:uniconnect/utils/navigation_wrapper.dart';

import '../ui/auth/auth_state_provider.dart';
import '../ui/community/community_form.dart';
import '../ui/community/community_screen.dart';
import '../ui/community/explore_community.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/search/search_screen.dart';
import '../ui/setting/setting_screen.dart';
import '../ui/setting/widgets/manage_profile.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: Routes.loginOrSignup,

    redirect: (context, state) {
      if (authAsync.isLoading) return null;

      if (authAsync.hasError) {
        return Routes.loginOrSignup;
      }

      final auth = authAsync.value!;
      final isLoggedIn = auth.isAuthenticated;

      final isAuthPage = state.matchedLocation == Routes.loginOrSignup;

      if (!isLoggedIn && !isAuthPage) {
        return Routes.loginOrSignup;
      }

      if (isLoggedIn && isAuthPage) {
        return Routes.home;
      }

      return null;
    },
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
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return MessageScreen(
            receiverId: data['userId']!,
            receiverName: data['username']!,
          );
        },
      ),
      GoRoute(
        path: Routes.setting,
        builder: (context, state) => const SettingScreen(),
      ),
      GoRoute(
        path: Routes.manageProfile,
        builder: (context, state) => const ManageProfile(),
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
          final isCreated = state.extra as bool;
          return CommunityScreen(communityId: id, isCreated: isCreated);
        },
      ),

      // Experts
      GoRoute(
        path: Routes.expertSignup,
        builder: (context, state) => ExpertSignupScreen(),
      ),
    GoRoute(
        path: Routes.expertProfile,
        builder: (context, state) => ExpertAcademicProfileScreen(),
      ),
    ],
  );
});
