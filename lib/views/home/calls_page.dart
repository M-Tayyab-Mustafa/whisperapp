import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  String currentUser = FirebaseAuth.instance.currentUser!.uid;

  DateTime getTime(String userStatus) {
    DateTime? dateTime = DateTime.tryParse(userStatus);
    if (dateTime != null) {
      return dateTime;
    } else {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Calls",
          style: GoogleFonts.lato(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade300,
      body: StreamBuilder(
          stream:
              FirebaseFirestore.instance.collection('users').doc(currentUser).collection('call_history').snapshots(),
          builder: (context, streamSnapshot) {
            if (streamSnapshot.hasData) {
              if (streamSnapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                  itemBuilder: (context, index) {
                    streamSnapshot.data!.docs.sort((a, b) => b['time'].compareTo(a['time']),);
                    var doc = streamSnapshot.data!.docs[index];
                    return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(doc.data()['call_by_me'] ? currentUser : doc.data()['mate_uid'])
                            .get(),
                        builder: (context, featureSnapShot) {
                          if (streamSnapshot.hasData) {
                            return ListTile(
                              leading:   CircleAvatar(
                                radius: 25,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: featureSnapShot.data?.data()!['photoUrl'] != null? Image.network(
                                    featureSnapShot.data?.data()!['photoUrl'],
                                    height: 25 * 2,
                                    width: 25 * 2,
                                    fit: BoxFit.fill,
                                  ):Container(),
                                ),
                              ),
                              title: Text(featureSnapShot.data?.data()!['username']??''),
                              subtitle: Text(
                                  '${doc.data()['call_type'].toUpperCase()} ${doc.data()['call_by_me'] ? '\u{2197}' : '\u{2199}'} \u{2022}'),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        });
                  },
                );
              } else {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.only(top: 0),
                  color: AppTheme.scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Call History
                      Expanded(
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                "No recent calls",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
