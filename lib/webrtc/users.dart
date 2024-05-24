import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:whisperapp/webrtc/signalling.dart';

class User {
  // Add your user data fields here (e.g., name, email)
  final String name;
  final String email;
  final String? photoUrl; // Optional field for avatar URL
  
  User({required this.name, required this.email, this.photoUrl});

  // Factory constructor to create a User object from a Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    return User(
      name: doc['username'] as String,
      email: doc['email'] as String,
    );
  }
}

class UserListScreen extends StatelessWidget {
  Future<List<User>>? users;
  String? roomId;
  UserListScreen({this.users});
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: FutureBuilder<List<User>>(
        future: users ?? getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userList = snapshot.data!;
          return ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return ListTile(
                leading: 
                    CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: IconButton(
                  icon: Icon(Icons.videocam),
                  onPressed: () async {
                    
                    // roomId = await signaling.createRoom(_remoteRenderer);
                   String id =await getRoomID().then((value) => value);

                    print("Get Room ID........................ ${id}");
                    // Implement video call functionality here
                    print('Initiating video call with ${user.name}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<User>> getAllUsers() async {

    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');
    final querySnapshot = await usersCollection.get();

    final users = querySnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    return users;
  }
}


Future<String> getRoomID(){
   Signaling  signaling = Signaling();
   RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  return signaling.createRoom(_localRenderer);
}
