import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/route_class.dart';
import '../../theme/app_theme.dart';
import '../../utils/images.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    Get.offAllNamed(RouteClass.checkUserState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
      ),
      body: splashScreenLayout(),
    );
  }

  Widget splashScreenLayout() {
    const primaryColor = Color(0xFF200E32);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Center(
              child: Image.asset(
                Images.splashImage,
                height: 200,
                width: 200,
                color: primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "from",
                      style: GoogleFonts.lato(
                        color: Colors.grey,
                      ),
                    ),
                    // From Text
                    TextSpan(
                      text: "\nCOMSATS",
                      style: GoogleFonts.lato(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
