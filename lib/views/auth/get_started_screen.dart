import 'package:flutter/material.dart';
import 'package:whisperapp/views/auth/signup_page.dart';
import 'package:whisperapp/views/auth/welcome/data.dart';
import 'package:whisperapp/views/auth/welcome/page_view_slide.dart';

import '../../theme/app_theme.dart';
import '../../widgets/round_button.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  late int _isActiveIndex;

  @override
  void initState() {
    _pageController = PageController();
    _isActiveIndex = 0;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChange({required int index}) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeIn);
    setState(() {
      _isActiveIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7895);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (value) => _handlePageChange(index: value),
                        itemCount: slides.length,
                        itemBuilder: (context, index) {
                          return PageViewSlide(
                            slide: slides[index],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 50.0,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < slides.length; i++)
                            Container(
                              margin: const EdgeInsets.only(right: 10.0),
                              width: _isActiveIndex == i ? 15.0 : 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: _isActiveIndex == i ? primaryColor : primaryColor,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              // Reduced the SizedBox height to bring the buttons closer to the PageView
              // ... other code

              const SizedBox(height: 10.0),
              RoundButton(
                title: 'LogIn',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LogInScreen()));
                },
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 10.0), // Space before the divider
              const Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20), // Increase padding to move the dividers inside
                      child: Divider(
                        color: primaryColor,
                        thickness: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20), // Increase padding to move the dividers inside
                      child: Divider(
                        color: primaryColor,
                        thickness: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0), // Space after the divider
              RoundButton(
                title: 'Register',
                titleColor: const Color(0xFF1E7895),
                color: const Color(0xFFD2E4E9),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                },
                fontWeight: FontWeight.bold,
              ),
              // Optionally, adjust the space between the 'Sign In' button and the bottom of the screen as needed
              SizedBox(height: 70.0)
            ],
          ),
        ),
      ),
    );
  }
}
