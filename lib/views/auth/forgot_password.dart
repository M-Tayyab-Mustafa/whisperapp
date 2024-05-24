import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/utilities.dart';
import '../../widgets/round_button.dart';




class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final auth = FirebaseAuth.instance;

  void _sendCodeAndNavigate() async {
    try {
      await auth.sendPasswordResetEmail(email: emailController.text.trim());
      utilities().toastMessage('We have sent you a link. Check your email.');
      // Navigate to OTPVerificationScreen


    } on FirebaseAuthException catch (e) {
      utilities().toastMessage(e.message ?? 'An error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color customColor = Color(0xFF44D7B6);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: customColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Increase padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,

        children: <Widget>[
          const Text(
            'Forgot Password ?',
            style: TextStyle(
              fontSize: 33.0,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Adjust the title color
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 16.0),
          const Text(
            "Please enter the email linked with your account we will send you a link.",
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.black, // Adjust the subtitle color
            ),
            textAlign: TextAlign.start,
          ),
            const SizedBox(height: 20), // Add more space
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',

                prefixIcon: Icon(Icons.email, color: Colors.grey),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey), // Set underline border color
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty ) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20), // Add more space
            RoundButton(
              title: 'Send Link',
              fontWeight: FontWeight.bold,// Change button text

              onTap: _sendCodeAndNavigate,
            ),
          ],
        ),
      ),
    );
  }
}
