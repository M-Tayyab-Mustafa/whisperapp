import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';

class ResetPasswordPage extends StatefulWidget {
  ResetPasswordPage({Key? key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  TextEditingController emailController = TextEditingController();
  AuthController authController = Get.put(AuthController());
  CustomLoader customLoader = CustomLoader();
  FocusNode emailNode = FocusNode();
  bool isValidEmail = false;

  @override
  Widget build(BuildContext context) {
    const Color customColor = Color(0xFF44D7B6);
    const primaryColor = Color(0xFF1E7895);
    const fieldColor = Color(0xFFEFEFEF);

    return GestureDetector(
      onTap: () {
        emailNode.unfocus();
        setState(() {});
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppTheme.scaffoldBackgroundColor,
          title: Text(
            "Reset Password",
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
            icon: Icon(Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset(
                'assets/images/forgot.png',
                width: 200,
                height: 200, // Replace with your asset path

                color: primaryColor,
              ), // Replace with your asset image path
              const SizedBox(height: 24),
              Text(
                'Forgot password ?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email linked to your account, and we will send you a link to reset your password.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: emailController,
                  focusNode: emailNode,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (text) {
                    setState(() {
                      isValidEmail = isEmailValid(text);
                    });
                  },
                  onTap: () {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter email',
                    filled: true,
                    fillColor: fieldColor,
                    prefixIcon: const Icon(Icons.mail, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CupertinoButton(
                    borderRadius: BorderRadius.circular(10),
                    color: primaryColor,
                    child: Text(
                      "Reset Password",
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (isValidEmail) {
                        customLoader.showLoader(context);
                        authController.resetPassword(
                          email: emailController.text.trim(),
                          customLoader: customLoader,
                        );
                      } else {
                        Get.snackbar("Error", "Enter a valid email");
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    return emailRegex.hasMatch(email);
  }
}
