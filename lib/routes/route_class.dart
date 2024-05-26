
import 'package:get/get.dart';

import '../views/auth/check_user_state.dart';
import '../views/auth/get_started_screen.dart';

import '../views/auth/login_screen.dart';
import '../views/auth/reset_password.dart';
import '../views/auth/signup_page.dart';
import '../views/auth/splashPage.dart';
import '../views/calls/ringing.dart';
import '../views/home/home_page.dart';
import '../views/settings/app_settings.dart';

class RouteClass {
  static String splashPage = "/splashPage";
  static String letsYouIn = "/GetStartedScreen";
  static String loginPage = "/LogInScreen";
  static String createAccountPage = "/createAccountPage";
  static String resetPasswordPage = "/resetPasswordPage";
  static String homePage = "/homePage";
  static String appSettingsPage = "/appSettingsPage";
  static String checkUserState = "/checkUserState";

  static List<GetPage> routes = [
    GetPage(name: splashPage, page: () => const SplashPage()),
    GetPage(name: letsYouIn, page: () =>  const WelcomeScreen()),
    GetPage(name: loginPage, page: () => const LogInScreen()),
    GetPage(name: createAccountPage, page: () => const SignUpScreen()),
    GetPage(name: resetPasswordPage, page: () => ResetPasswordPage()),
    GetPage(name: homePage, page: () => const HomePage()),
    GetPage(name: appSettingsPage, page: () => AppSettingsPage()),
    GetPage(name: checkUserState, page: () => const CheckUserState()),
  ];
}
