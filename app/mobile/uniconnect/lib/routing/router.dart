import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniconnect/routing/routes.dart';
import 'package:uniconnect/ui/auth/auth_screen.dart';
import 'package:uniconnect/ui/auth/login/widgets/forget_email_screen.dart';
import 'package:uniconnect/ui/auth/onboarding/academic_profile/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/personalization/create_profile.dart';
import 'package:uniconnect/ui/auth/onboarding/verify_email/verify_email_screen.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/academic_profile.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/signup/expert_signup_screen.dart';
import 'package:uniconnect/ui/auth/onboarding_experts/verify_university/verify_university.dart';
import 'package:uniconnect/ui/events/detailed_event_screen.dart';
import 'package:uniconnect/ui/events/explore_events.dart';
import 'package:uniconnect/ui/mentorship/explore_mentorship.dart';
import 'package:uniconnect/ui/message/message_screen.dart';
import 'package:uniconnect/ui/notification/widgets/incoming_networks.dart';
import 'package:uniconnect/ui/post/create_post.dart';
import 'package:uniconnect/ui/profile/widgets/event_form.dart';
import 'package:uniconnect/ui/setting/widgets/add_course_form_screen.dart';
import 'package:uniconnect/ui/setting/widgets/affilate_screen.dart';
import 'package:uniconnect/ui/setting/widgets/saved_screen.dart';
import 'package:uniconnect/utils/navigation_wrapper.dart';

import '../ui/auth/auth_state_provider.dart';
import '../ui/auth/onboarding/verify_identity/verify_identity.dart';
import '../ui/community/community_form.dart';
import '../ui/community/community_screen.dart';
import '../ui/community/create_community_post.dart';
import '../ui/community/explore_community.dart';
import '../ui/network/network_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/search/search_screen.dart';
import '../ui/setting/setting_screen.dart';
import '../ui/setting/widgets/events_screen.dart';
import '../ui/setting/widgets/manage_profile.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: Routes.loginOrSignup,

    redirect: (context, state) {
      return authAsync.when(
        loading: () => null,
        error: (err, stack) => Routes.loginOrSignup,
        data: (auth) {
          final isLoggedIn = auth.isAuthenticated;

          final publicRoutes = [
            Routes.loginOrSignup,
            Routes.verifyEmail,
            Routes.verifyIdentity,
            Routes.onboardingAcademic,
            Routes.onBoardingProfile,
            Routes.forgetEmailPath,
            Routes.expertSignup,
            Routes.expertVerifyUni,
            Routes.expertProfile,
          ];

          final isPublicRoute = publicRoutes.contains(state.matchedLocation);

          if (!isLoggedIn && !isPublicRoute) {
            return Routes.loginOrSignup;
          }

          if (isLoggedIn && isPublicRoute) {
            return Routes.home;
          }

          return null;
        },
      );
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
          path: Routes.forgetEmailPath,
          builder: (context, state) {
            final email = state.extra as String;
            return ForgetEmailScreen(email: email);
          }
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
          final data = state.extra as Map<String, dynamic>;
          return MessageScreen(
            receiverId: data['receiverId'] as String,
            receiverName: data['username'] as String,
            profileImage: data['profileImage'] as String?,
            chatId: data['chatId'] as String?,
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
        path: Routes.affiliate,
        builder: (context, state) => const AffiliateScreen(),
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
        path: Routes.verifyIdentity,
        builder: (context, state) => const IdentityVerificationScreen(),
      ),
      GoRoute(
        path: Routes.incomingNetworks,
        builder: (context, state) => const NetworksIncomingScreen(),
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
      GoRoute(
        path: Routes.communityCreatePostScreen,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateCommunityPostScreen(communityId: id);
        },
      ),
      GoRoute(
        path: Routes.networks,
        builder: (context, state) => NetworkScreen(),
      ),
      GoRoute(
        path: Routes.eventsScreen,
        builder: (context, state) {
          final id = state.uri.queryParameters['userId'];
          return EventScreen(userId: id);
        },
      ),
      GoRoute(
        path: Routes.addEvent,
        builder: (context, state) => EventFormPage(),
      ),
      GoRoute(
        path: Routes.exploreEvents,
        builder: (context, state) => ExploreEventsScreen(),
      ),
      GoRoute(
        path: Routes.exploreMentors,
        builder: (context, state) => ExploreMentorshipScreen(),
      ),
      GoRoute(
        path: Routes.detailEventsScreen,
        builder: (context, state) => EventDetailScreen(),
      ),

      // Experts
      GoRoute(
        path: Routes.expertSignup,
        builder: (context, state) => ExpertSignupScreen(),
      ),
      GoRoute(
        path: Routes.expertVerifyUni,
        builder: (context, state) => const ExpertVerifyUni(),
      ),
      GoRoute(
        path: Routes.expertProfile,
        builder: (context, state) => ExpertAcademicProfileScreen(),
      ),
      GoRoute(
        path: Routes.addCourse,
        builder: (context, state) => AddCourseScreen(),
      ),
    ],
  );
});
