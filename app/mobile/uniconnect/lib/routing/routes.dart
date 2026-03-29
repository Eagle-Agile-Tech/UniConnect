abstract final class Routes {
  static const String loginOrSignup = '/auth';
  static const String verifyEmail = '/verifyEmail';
  static const String onboardingAcademic = '/onboarding/academic';
  static const String onBoardingProfile = '/onboarding/profile';
  static const String home = '/';
  static const String createPost = '/createPost';
  static const String search = '/search';
  static const String messaging = '/messaging';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String setting = '/setting';
  static const String manageProfile = '/setting/manageProfile';
  static const String saved = '/saved';
  static const String post = '/createPost';
  static const String createCommunity = '/createCommunity';
  static const String communities = '/communityCenter';
  static String userProfile(String userId) => '/userProfile/$userId';
  static const String userProfilePath = '/userProfile/:userId';
  static String community(String id) => '/community/$id';
  static const String communityScreen =  '/community/:id';

  // Expert
  static const String expertSignup = '/expert/signup';
  static const String expertVerifyUni = '/expert/verifyUni';
  static const String expertProfile = '/expert/profile';
}