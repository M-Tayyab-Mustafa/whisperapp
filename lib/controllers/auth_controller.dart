

import 'dart:io' as io; // Import dart:io with a prefix


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../model/user_model.dart';
import '../routes/route_class.dart';
import '../widgets/custom_loader.dart';
// file_handler.dart




class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  // Function to update profile picture.
  Future<void> updateUserProfilePcture({
    required io.File imageFile,
    required CustomLoader customLoader,
  }) async {
    try {
      String userUid = FirebaseAuth.instance.currentUser!.uid;
      String userProfilePicture = await uploadImageToStorage(imageFile, userUid);
      await _firestore.collection("users").doc(userUid).update({
        "photoUrl": userProfilePicture,
      });
      customLoader.hideLoader();
    } catch (e) {
      print("Error updating user profile picture: $e");
      customLoader.hideLoader(); // Ensure loader is hidden in case of error
    }
  }

// Updated to accept File directly
  Future<String> uploadImageToStorage(io.File imageFile, String userUid) async {
    Reference ref = firebaseStorage.ref().child("usersProfilePictures/$userUid.png");
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }


  // Function to update user status
  Future<void> updateUserStatus(String status) async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .update({"userStatus": status});
      } catch (e) {}
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
    required CustomLoader customLoader,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await updateUserStatus("online");
      await updateUserToken();
      customLoader.hideLoader();
      Get.offAllNamed(RouteClass.checkUserState);
    } catch (e) {
      customLoader.hideLoader();
      Get.snackbar("Error logging in", "$e");
    }
  }

  // Reset Password
  Future<void> resetPassword({
    required String email,required CustomLoader customLoader,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar("Success", "Check your email to change password!");
customLoader.hideLoader();
    } catch (e) {
      Get.snackbar("Error sending password reset email", "$e");
      customLoader.hideLoader();
    }

  }

  // Logout
  Future<void> logout({required CustomLoader customLoader}) async {
    try {
      await updateUserStatus("${DateTime.now()}");
      await _auth.signOut();
      customLoader.hideLoader();
      Get.offAllNamed(RouteClass.checkUserState);
    } catch (e) {
      customLoader.hideLoader();
      Get.snackbar("Error logging out", "$e");
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        // Remove user data from Cloud Firestore
        await _firestore.collection('users').doc(user.uid).delete();
      }
    } catch (e) {
      print("Error deleting account: $e");
    }
  }
  
  //Update user token
  Future<void> updateUserToken() async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      String? fcmToken = await messaging.getToken();
      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .update({"fcmToken": fcmToken});
      } catch (e) {}
    }
  }
}
