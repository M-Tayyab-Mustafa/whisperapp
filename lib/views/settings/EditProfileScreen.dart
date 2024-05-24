import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../widgets/round_button.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final TextEditingController _dobController = TextEditingController();

  // User attributes
  String _name = '';
  DateTime _dob = DateTime.now();
  String _gender = '';
  List<String> _interests = []; // Assuming interests are stored as List<String>
  String _country = '';
  String _province = '';
  String _city = '';

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(currentUserUid).get();
      final userData = doc.data()!;
      setState(() {
        _name = userData['username'];
        _dob = DateFormat('yyyy-MM-dd').parse(userData['dob']);
        _gender = userData['gender'];
        _interests = List<String>.from(userData['interests']);
        _country = userData['country'];
        _province = userData['province'];
        _city = userData['city'];
        _dobController.text = DateFormat('yyyy-MM-dd').format(_dob);
      });
    } catch (e) {
      print(e); // Consider using a more user-friendly error handling
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _name,
        'dob': DateFormat('yyyy-MM-dd').format(_dob),
        'gender': _gender,
        'interests': _interests,
        'country': _country,
        'province': _province,
        'city': _city,
      });
      Navigator.of(context).pop(true); // Optionally, indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
    setState(() => _isLoading = false);
  }
  bool _containsNumbers(String input) {
    return RegExp(r'[0-9]').hasMatch(input);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              initialValue: _name,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                } else if (_containsNumbers(value)) {
                  return 'Name cannot contain numbers';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(labelText: 'Date of Birth'),
              readOnly: true,
              onTap: () async {
                FocusScope.of(context).requestFocus(new FocusNode());
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dob,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null && picked != _dob) {
                  setState(() {
                    _dob = picked;
                    _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                  });
                }
              },
            ),
            DropdownButtonFormField(
              value: _gender.isNotEmpty ? _gender : null,
              items: ['Male', 'Female', 'Other']
                  .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _gender = value.toString());
              },
              decoration: InputDecoration(labelText: 'Gender'),
            ),
            TextFormField(
              initialValue: _interests.join(', '),
              decoration: InputDecoration(labelText: 'Interests (comma separated)'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter at least one interest';
                } else if (_containsNumbers(value)) {
                  return 'Interests cannot contain numbers';
                }
                return null;
              },
              onSaved: (value) => _interests = value!.split(',').map((e) => e.trim()).toList(),
            ),
            TextFormField(
              initialValue: _country,
              decoration: InputDecoration(labelText: 'Country'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your country';
                } else if (_containsNumbers(value)) {
                  return 'Country cannot contain numbers';
                }
                return null;
              },
              onSaved: (value) => _country = value!,
            ),

            TextFormField(
              initialValue: _province,
              decoration: InputDecoration(labelText: 'Province'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your province';
                } else if (_containsNumbers(value)) {
                  return 'Province cannot contain numbers';
                }
                return null;
              },
              onSaved: (value) => _province = value!,
            ),

            TextFormField(
              initialValue: _city,
              decoration: InputDecoration(labelText: 'City'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                } else if (_containsNumbers(value)) {
                  return 'City cannot contain numbers';
                }
                return null;
              },
              onSaved: (value) => _city = value!,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0),
              child: RoundButton(
                title: 'Save Changes',
                onTap: _saveProfile,
                fontWeight: FontWeight.bold,

              ),
            ),
          ],
        ),
      ),
    );
  }
}
