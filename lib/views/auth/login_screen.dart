import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:email_otp/email_otp.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisperapp/views/auth/reset_password.dart';
import 'package:whisperapp/views/auth/signup_page.dart';

import '../../theme/app_theme.dart';
import '../../utils/utilities.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/round_button.dart';
import 'otp_verification.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final EmailOTP myAuth = EmailOTP(); // Email OTP instance
  bool _isPasswordHidden = true;
  CustomLoader customLoader = CustomLoader();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!await isConnected()) {
      utilities().toastMessage('Network error: No internet connection');
      return;
    }

    customLoader.showLoader(context); // Show loader when the login process starts
    setState(() {
      loading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Send OTP to user's email
      myAuth.setConfig(
          appEmail: "whisperchat@gmail.com",
          appName: "whisperchat",
          userEmail: emailController.text.trim(),
          otpLength: 6,
          otpType: OTPType.digitsOnly);

      if (await myAuth.sendOTP()) {
        customLoader.hideLoader(); // Hide loader on successful OTP sending
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                      email: emailController.text.trim(),
                      auth: myAuth,
                    )));
      } else {
        customLoader.hideLoader(); // Hide loader if sending OTP fails
        utilities().toastMessage("Failed to send OTP");
      }
    } on FirebaseAuthException catch (e) {
      customLoader.hideLoader(); // Hide loader if there's a Firebase Auth exception
      String message = 'email or password incorrect.';
      utilities().toastMessage(message);
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F5F5);
    const fieldColor = Color(0xFFEFEFEF);
    const primaryColor = Color(0xFF1E7895);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        title: Text(
          "SignIn",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                    child: Image.asset(
                  'assets/images/login.png', // Replace with your asset path
                  width: 100, // Set your width and height as needed
                  height: 100,
                  color: primaryColor,
                )),
                const SizedBox(height: 16),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Hello there, sign in to continue!',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32.0), // Add space before the form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Your email',
                          filled: true,
                          // Add this
                          fillColor: fieldColor,
                          // Use the light gray color for the input field background
                          prefixIcon: const Icon(Icons.mail, color: Colors.grey),
                          border: OutlineInputBorder(
                            // Change this to an outline border
                            borderRadius: BorderRadius.circular(13),
                            // Add border radius
                            borderSide: BorderSide.none, // No actual border, just the fill and the rounded corner
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b').hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        keyboardType: TextInputType.text,
                        controller: passwordController,
                        obscureText: _isPasswordHidden, // This will toggle the text visibility
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: fieldColor,
                          prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              // Change the icon based on whether the password is hidden or not
                              _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // Update the state to toggle password visibility
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            customLoader.showLoader(context); // Show the loader
                            await Future.delayed(Duration(milliseconds: 500)); // Simulate some loading process
                            customLoader.hideLoader(); // Hide the loader
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: primaryColor, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Add space before the button
                      RoundButton(
                        title: 'Log in',
                        fontWeight: FontWeight.w900,
                        onTap: () {
                          if (_formKey.currentState!.validate()) {
                            login();
                          }
                        },
                      ),

                      const SizedBox(height: 55),
                      // Add space before the register link
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          const SizedBox(height: 20), // Add space between the text and the button
                          RoundButton(
                            title: 'Register',
                            titleColor: Color(0xFF1E7895),
                            color: Color(0xFFD2E4E9),
                            onTap: () async {
                              customLoader.showLoader(context); // Show the loader
                              await Future.delayed(Duration(milliseconds: 500)); // Wait for half a second
                              // Make sure to hide the loader if you are still in the same context and the loader was shown
                              customLoader.hideLoader();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpScreen()),
                              ).then((_) =>
                                  customLoader.hideLoader()); // Hide the loader when returning back to this screen
                            },
                            fontWeight: FontWeight.w900,
                          ),

                          // Add any additional styling to RoundButton if necessary
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
