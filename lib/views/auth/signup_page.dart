import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/notifications_controller.dart';
import '../../model/user_model.dart'; // Make sure this import points to your UserModel class
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/round_button.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final interestsController = TextEditingController();
  final locationController = TextEditingController();
  final dobController = TextEditingController();
  String gender = 'Gender';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true; // Add this line
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // For Date of Birth
  // Default value
  CustomLoader customLoader = CustomLoader();

  @override
  void dispose() {
    usernameController.dispose();
    interestsController.dispose();
    locationController.dispose();
    dobController.dispose();
    emailController.dispose();
    passwordController.dispose();

    confirmPasswordController.dispose();
    super.dispose();
  }

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) {
      return; // No further action if the form isn't valid
    }

    customLoader.showLoader(context); // Show the custom loader

    String email = emailController.text.trim();
    String username = usernameController.text.trim();
    List<String> locationParts = locationController.text.split(',').map((s) => s.trim()).toList();
    List<String> interestsList =
        interestsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text,
      );

      User? user = userCredential.user;
      // Assuming messaging.getToken() is a part of your FCM configuration
      String? fcmToken = await messaging.getToken(); // Ensure 'messaging' is defined and getToken() is available

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          country: locationParts.length > 0 ? locationParts[0] : "",
          province: locationParts.length > 1 ? locationParts[1] : "",
          city: locationParts.length > 2 ? locationParts[2] : "",
          dob: dobController.text.trim(),
          gender: gender,
          interests: interestsList,
          photoUrl: 'none', // Provide a default or placeholder photo URL
          fcmToken: fcmToken ?? "",
          isVerified: false,
          latitude: 0.0, // Default latitude value
          longitude: 0.0, // Default longitude value
          userStatus: 'online',
        );

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(newUser.toMap());

        customLoader.hideLoader(); // Hide the loader on success before navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogInScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      customLoader.hideLoader(); // Make sure to hide the loader on error
      if (e.code == 'email-already-in-use') {
        showErrorSnackBar('This email already exists');
      } else {
        showErrorSnackBar("Failed to sign up: ${e.message}");
      }
    } catch (e) {
      customLoader.hideLoader(); // Hide loader on any other exceptions
      showErrorSnackBar("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF200E32);
    const fieldColor = Color(0xFFEFEFEF);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.scaffoldBackgroundColor, // Make sure this is correctly referenced
        title: Text(
          "SignUp",
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
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 10), // Reduced space
                  const Text(
                    'Create an account',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    // Removed const to allow textAlign
                    'Join now to discover and connect with nearby people who share your interests!',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.left, // Align text to the left
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name ',
                      filled: true,
                      // Add this
                      fillColor: fieldColor,
                      // Use the light gray color for the input field background
                      prefixIcon: const Icon(Icons.person, color: Colors.grey),
                      border: OutlineInputBorder(
                        // Change this to an outline border
                        borderRadius: BorderRadius.circular(13),
                        // Add border radius
                        borderSide: BorderSide.none, // No actual border, just the fill and the rounded corner
                      ),
                    ),
                    validator: (value) {
                      String trimmedValue = value?.trim() ?? '';
                      if (trimmedValue.isEmpty) {
                        return 'Please enter your name';
                      }
                      // Check if the username contains only letters
                      if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(trimmedValue)) {
                        return 'Username must contain only letters and space';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: interestsController,
                    decoration: InputDecoration(
                      hintText: 'Interests (separated by commas)',
                      filled: true,
                      // Add this
                      fillColor: fieldColor,
                      // Use the light gray color for the input field background
                      prefixIcon: const Icon(Icons.interests, color: Colors.grey),
                      border: OutlineInputBorder(
                        // Change this to an outline border
                        borderRadius: BorderRadius.circular(13),
                        // Add border radius
                        borderSide: BorderSide.none, // No actual border, just the fill and the rounded corner
                      ),
                    ),
                    validator: (value) {
                      String trimmedValue = value?.trim() ?? '';
                      if (trimmedValue.isEmpty) {
                        return 'Please enter your interests';
                      }
                      // Check if the interests contain only letters, commas, and spaces
                      if (!RegExp(r'^[a-zA-Z,\s]+$').hasMatch(trimmedValue)) {
                        return 'Interests must contain only letters, commas, and spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: locationController, // Ensure you have defined this controller in your class
                    decoration: InputDecoration(
                      hintText: 'Country, Province, City',
                      filled: true,
                      fillColor: fieldColor, // Ensure you have defined this color
                      prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                      border: OutlineInputBorder(
                        // Change this to an outline border
                        borderRadius: BorderRadius.circular(13),
                        // Add border radius
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your location';
                      }
                      List<String> parts = value.split(',');
                      if (parts.length != 3 || parts.any((part) => part.trim().isEmpty)) {
                        return 'Please enter location in the format: Country, Province, City';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dobController,
                    decoration: InputDecoration(
                      hintText: 'Date of Birth (YYYY-MM-DD)',
                      filled: true,
                      fillColor: fieldColor, // Ensure you have defined this color
                      prefixIcon: const Icon(Icons.date_range, color: Colors.grey),
                      border: OutlineInputBorder(
                        // Change this to an outline border
                        borderRadius: BorderRadius.circular(13),
                        // Add border radius
                        borderSide: BorderSide.none,
                      ),
                    ),
                    readOnly: true,

                    // Prevent keyboard from appearing
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      // Additional validation to ensure the date is not in the future
                      DateTime? dob = DateFormat('yyyy-MM-dd').parse(value, true).toLocal();
                      if (dob.isAfter(DateTime.now())) {
                        return 'Date of birth cannot be in the future';
                      }
                      return null;
                    }, // Date picker
                  ),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: gender,
                    onChanged: (value) => setState(() => gender = value!),
                    items: <String>['Gender', 'Male', 'Female', 'Other'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    decoration: InputDecoration(
                      hintText: 'Select Gender',
                      filled: true,
                      fillColor: fieldColor, // Use the same fieldColor as TextFormField
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      border: OutlineInputBorder(
                        // Use the same border styling
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == 'Gender') {
                        return 'Please select a gender';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    controller: confirmPasswordController,
                    obscureText: _isConfirmPasswordHidden, // Assuming you've implemented separate visibility control
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      filled: true,
                      fillColor: fieldColor,
                      prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordHidden ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          // Toggle confirm password visibility
                          setState(() {
                            _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
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
                        return 'Please confirm your password';
                      } else if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),
                  RoundButton(
                    title: 'Sign Up',
                    fontWeight: FontWeight.bold,
                    loading: loading,
                    onTap: signUp,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LogInScreen()),
                          );
                        },
                        child: const Text('LogIn', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
