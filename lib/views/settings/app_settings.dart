import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatars.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/custom_tile.dart';
import 'EditProfileScreen.dart';

class AppSettingsPage extends StatefulWidget {
  AppSettingsPage({Key? key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  AuthController authController = Get.put(AuthController());
  CustomLoader customLoader = CustomLoader();
  String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // List<String> avatarsList = [
  //   Avatars.boy_1,
  //   Avatars.boy_2,
  //   Avatars.boy_3,
  //   Avatars.girl_1,
  //   Avatars.girl_2,
  //   Avatars.girl_3,
  // ];
  // int selectedAvatar = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.only(top: 0.8),
        decoration: const BoxDecoration(
          color: AppTheme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // My account
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection("users").doc(currentUserUid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return ListTile(
                    onTap: () {},
                    title: Text(
                      "@username",
                      style: GoogleFonts.lato(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "loading...",
                      style: GoogleFonts.lato(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppTheme.mainColor,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: SvgPicture.asset(
                      "assets/icons/qr.svg",
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                } else if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    onTap: () {},
                    title: Text(
                      "@username",
                      style: GoogleFonts.lato(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "loading...",
                      style: GoogleFonts.lato(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: AppTheme.mainColor,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: SvgPicture.asset(
                      "assets/icons/qr.svg",
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                } else {
                  String username = snapshot.data!["username"];
                  String email = snapshot.data!["email"];
                  bool hasProfilePicture = snapshot.data!["photoUrl"] != "none";
                  bool isVerified = snapshot.data!["isVerified"];

                  return ListTile(
                    onTap: () {},
                    title: Row(
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.lato(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        isVerified
                            ? const Icon(
                                Icons.verified,
                                color: AppTheme.mainColor,
                                size: 16,
                              )
                            : const SizedBox(),
                      ],
                    ),
                    subtitle: Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    leading: GestureDetector(
                      onTap: () {
                        showChooseProfilePicture(context);
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: AppTheme.loaderColor,
                        ),
                        child: Stack(
                          children: [
                            hasProfilePicture
                                ? CachedNetworkImage(
                                    imageUrl: snapshot.data!["photoUrl"],
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                    fit: BoxFit
                                        .cover, // This line ensures that the image covers the space without distorting the aspect ratio
                                    width: 50, // Set the width to fit your layout
                                    height: 50, // Set the height to fit your layout
                                    imageBuilder: (context, imageProvider) => Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover, // Ensures the image covers the container
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: SvgPicture.asset(
                                      CustomIcons.camera,
                                      height: 22,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
            // Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Divider(
                color: Colors.grey.shade300,
              ),
            ),
            CustomTile(
              title: "Edit Profile",
              icon: CustomIcons.profile,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen()));
              },
            ),
            const SizedBox(height: 10),
            CustomTile(
              title: "Notifications",
              icon: CustomIcons.notification,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            CustomTile(
              title: "Storage & Data",
              icon: CustomIcons.file,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            CustomTile(
              title: "Security",
              icon: CustomIcons.security,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            CustomTile(
              title: "Help Center",
              icon: CustomIcons.help,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            CustomTile(
              title: "Invite friends",
              icon: CustomIcons.friends,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _showLogoutConfirmation(context);
              },
              child: Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 240, 241),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8.0),
                    SvgPicture.asset(
                      CustomIcons.logout,
                      colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
                      height: 22,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      "Logout",
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                    const Expanded(child: Row()),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showChooseProfilePicture(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: Platform.isAndroid ? 220 : 270,
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose Profile Picture",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      _getImage(ImageSource.gallery);
                    },
                    child: Column(
                      children: [
                        Icon(Icons.photo_library, size: 50),
                        SizedBox(height: 10),
                        Text("Gallery"),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _getImage(ImageSource.camera);
                    },
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt, size: 50),
                        SizedBox(height: 10),
                        Text("Camera"),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      removeUserProfilePicture(customLoader: customLoader);
                    },
                    child: Column(
                      children: [
                        Icon(Icons.remove_circle_outline, size: 50),
                        SizedBox(height: 10),
                        Text("Remove"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path); // Convert to File object
      customLoader.showLoader(context); // Show loader before starting upload

      // Update to pass File object
      authController.updateUserProfilePcture(
        imageFile: imageFile,
        customLoader: customLoader,
      );
    } else {
      print("No image selected.");
    }
  }

  Future<void> removeUserProfilePicture({required CustomLoader customLoader}) async {
    customLoader.showLoader(context); // Show the loader when the process starts
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      // Remove the profile picture URL from Firestore by setting it to 'none'
      await _firestore.collection('users').doc(userUid).update({'photoUrl': 'none'});

      // Optionally delete the profile picture file from Firebase Storage
      // Note: This assumes you have the path or naming convention to find the file
      String filePath = 'usersProfilePictures/$userUid.png'; // Example path
      await firebaseStorage.ref(filePath).delete();

      customLoader.hideLoader(); // Hide the loader on success
      Get.snackbar("Success", "Profile picture removed successfully.");
    } catch (e) {
      print("Error removing profile picture: $e");
      customLoader.hideLoader(); // Ensure loader is hidden in case of failure
      Get.snackbar("Error", "Failed to remove profile picture.");
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
            "Logout",
            style: GoogleFonts.lato(),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: GoogleFonts.lato(),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(
                "Cancel",
                style: GoogleFonts.lato(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(
                "Logout",
                style: GoogleFonts.lato(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                customLoader.showLoader(context);
                authController.logout(customLoader: customLoader);
              },
            ),
          ],
        );
      },
    );
  }
}
