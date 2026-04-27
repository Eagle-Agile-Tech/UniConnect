abstract final class Routes {
  static const String loginOrSignup = '/auth';
  static const String verifyEmail = '/verifyEmail';
  static const String verifyIdentity = '/verifyIdentity';
  static const String onboardingAcademic = '/onboarding/academic';
  static const String onBoardingProfile = '/onboarding/profile';
  static const String home = '/';
  static const String createPost = '/createPost';
  static const String search = '/search';
  static const String messaging = '/messaging';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String forgetEmailPath = '/forgetEmail';
  static const String setting = '/setting';
  static const String manageProfile = '/setting/manageProfile';
  static const String saved = '/saved';
  static const String affiliate = '/affiliate';
  static const String post = '/createPost';
  static const String networks = '/network';
  static String events({String? userId}) =>
      userId == null ? '/events' : '/events?userId=$userId';
  static const String eventsScreen = '/events';
  static const String detailEventsScreen = '/detailEvent';
  static const String incomingNetworks = '/incomingNetworks';


  static const String addEvent = '/addEvent';
  static const String exploreEvents = '/exploreEvents';
  static const String exploreMentors = '/exploreMentorship';

  // Community
  static const String createCommunity = '/createCommunity';
  static const String communities = '/communityCenter';
  static String userProfile(String userId) => '/userProfile/$userId';
  static const String userProfilePath = '/userProfile/:userId';
  static String community(String id) => '/community/$id';
  static const String communityScreen =  '/community/:id';
  static String communityCreatePost(String id) => '/community/$id/createPost';
  static const String communityCreatePostScreen = '/community/:id/createPost';

  // Expert
  static const String expertSignup = '/expert/signup';
  static const String expertVerifyUni = '/expert/verifyUni';
  static const String expertProfile = '/expert/profile';
  static const String addCourse = '/expert/setting/addCourse';
}
