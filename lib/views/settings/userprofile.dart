import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePictureManager {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> showChooseProfilePicture(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery, context);
                  }),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera, context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove Current Picture'),
                onTap: () {
                  _removeProfilePicture();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      File imageFile = File(image.path);
      _uploadImage(imageFile, context);
    }

    Navigator.pop(context);
  }

  Future<void> _uploadImage(File imageFile, BuildContext context) async {
    String userId = _auth.currentUser!.uid;
    String filePath = 'profilePics/$userId.png';
    final ref = FirebaseStorage.instance.ref().child(filePath);

    try {
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      _firestore.collection('users').doc(userId).update({
        'photoUrl': imageUrl,
      });


    } catch (e) {
      // Handle errors
    }
  }

  Future<void> _removeProfilePicture() async {
    String userId = _auth.currentUser!.uid;
    // Specify the URL to your default image
    String defaultImageUrl = 'URL_to_your_default_image';
    _firestore.collection('users').doc(userId).update({
      'photoUrl': defaultImageUrl,
    });
  }
}
