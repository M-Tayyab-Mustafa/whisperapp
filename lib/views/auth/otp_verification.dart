import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:get/get.dart';
import 'package:whisperapp/views/home/home_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/round_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final EmailOTP auth;

  OtpVerificationScreen({Key? key, required this.email, required this.auth}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  late Timer _timer;
  int _start = 60; // 60 seconds countdown
  bool otpExpired = false;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
          (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            otpExpired = true; // Set OTP as expired
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> resendOTP() async {
    bool result = await widget.auth.sendOTP(); // This is a placeholder for your resend logic
    if (result) {
      setState(() {
        _start = 60; // Reset timer back to 60 seconds
        otpExpired = false; // Reset OTP expiration status
        startTimer();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP has been resent")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to resend OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const fieldColor = Color(0xFFEFEFEF);
    const primaryColor = Color(0xFF1E7895);
    return Scaffold(
      appBar: AppBar(
        title: Text("OTP Verification"),
        backgroundColor: AppTheme.scaffoldBackgroundColor, // Adjusted to your theme
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.1),

              Image.asset(
                'assets/images/otp.png', // Replace with your asset path
                width: 150,
                height: 150,
                color: primaryColor,
              ),
              // Your icon image
              SizedBox(height: 24),
              Text(
                'Verification code',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please enter the verification code\nsent to your email.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                widget.email, // Display the email
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                // textAlign: TextAlign.center,
                cursorColor: Theme
                    .of(context)
                    .primaryColor,
                decoration: InputDecoration(
                  hintText: 'Enter OTP',
                  filled: true,
                  fillColor: fieldColor,
                  // Use the light gray color for the input field background

                  border: OutlineInputBorder(
                    // Change this to an outline border
                    borderRadius: BorderRadius.circular(13),
                    // Add border radius
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Time remaining: $_start seconds',
                style: TextStyle(color: Colors.grey),
              ),

              SizedBox(height: 24),
              RoundButton(
                title: 'Submit',
                onTap: () async {
                  if (await widget.auth.verifyOTP(otp: otpController.text)) {
                    await updateUserToken();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()), // Adjusted to your home page path
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Invalid OTP")),
                    );
                  }
                },
                fontWeight: FontWeight.w900,
              ),

              SizedBox(height: 16),
              if (_start == 0)
                RoundButton(
                  title: 'Resend OTP',
                  titleColor: Color(0xFF1E7895),
                  color: Color(0xFFD2E4E9),
                  onTap: resendOTP,
                  fontWeight: FontWeight.w900,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateUserToken() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    log('New FCM Token $fcmToken');
    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).update({"fcmToken": fcmToken});
    } catch (e) {
      log(e.toString());
    }
  }
}
