import 'package:flutter/material.dart';
import 'package:uniconnect/ui/auth/signup/signup_screen.dart';
import 'login/login_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(

              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 4),
              insets: EdgeInsetsGeometry.symmetric(horizontal: 48)
            ),
            tabs: const [
              Tab(text: 'Log in'),
              Tab(text: 'Sign up'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const LoginScreen(),
            const SignupScreen(),
          ],
        ),
      ),
    );
  }
}