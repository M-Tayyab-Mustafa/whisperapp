class UserModel {
  final String uid;
  final String email;
  final String username;
  String country;
  String province;
  String city;
  String dob;
  String gender;
  List<String> interests;
  final String photoUrl;
  final String fcmToken;
  final bool isVerified;
  final double latitude;
  final double longitude;
  final String userStatus;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.country,
    required this.province,
    required this.city,
    required this.dob,
    required this.gender,
    required this.interests,
    required this.photoUrl,
    required this.fcmToken,
    required this.isVerified,
    required this.latitude,
    required this.longitude,
    required this.userStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'country': country,
      'province': province,
      'city': city,
      'dob': dob,
      'gender': gender,
      'interests': interests,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'isVerified': isVerified,
      'latitude': latitude,
      'longitude': longitude,
      'userStatus': userStatus,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      country: map['country'] ?? "",
      province: map['province'] ?? "",
      city: map['city'] ?? "",
      dob: map['dob'] ?? "",
      gender: map['gender'] ?? "Gender",
      interests: List<String>.from(map['interests'] ?? []),
      photoUrl: map['photoUrl'] ?? 'none',
      fcmToken: map['fcmToken'] ?? "",
      isVerified: map['isVerified'] ?? false,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      userStatus: map['userStatus'] ?? 'online',
    );
  }
}
