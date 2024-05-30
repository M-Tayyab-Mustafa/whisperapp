import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../calls/call_page.dart';

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
        // actions: [
        //   IconButton(
        //     onPressed: () async {
        //       String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
        //       CollectionReference collectionRef =
        //       FirebaseFirestore.instance.collection('users').doc(currentUserUid).collection("call_history");
        //       QuerySnapshot querySnapshot = await collectionRef.get();
        //       for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        //         await doc.reference.delete();
        //       }
        //     },
        //     icon: const Icon(Icons.delete),
        //   ),
        // ],
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser).collection('call_history').snapshots(),
          builder: (context, streamSnapshot) {
            if (streamSnapshot.hasData) {
              if (streamSnapshot.data!.docs.isNotEmpty) {
                return ListView.builder(
                  itemCount: streamSnapshot.data!.docs.length,
                  reverse: true,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    // streamSnapshot.data!.docs.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));
                    var doc = streamSnapshot.data!.docs[index];
                    return FutureBuilder(
                        future: FirebaseFirestore.instance.collection('users').doc(doc.data()['call_by_me'] ? currentUser : doc.data()['mate_uid']).get(),
                        builder: (context, featureSnapShot) {
                          if (streamSnapshot.hasData) {
                            return ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog.adaptive(
                                    contentPadding: const EdgeInsets.all(0),
                                    title: Text('\u{1F4DE} Call ${featureSnapShot.data?.data()!['username']}'),
                                    actionsAlignment: MainAxisAlignment.spaceBetween,
                                    actions: [
                                      ElevatedButton(
                                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColor)),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Get.to(
                                            () => CallPage(
                                              mateUid: doc.data()['mate_uid'],
                                              callType: "audio",
                                              mateName: featureSnapShot.data?.data()!['username'],
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Audio',
                                          style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColor)),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Get.to(
                                            () => CallPage(
                                              mateUid: doc.data()['mate_uid'],
                                              callType: "video",
                                              mateName: featureSnapShot.data?.data()!['username'],
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Video',
                                          style: TextStyle(color: Theme.of(context).secondaryHeaderColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                radius: 25,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(1000),
                                  child: featureSnapShot.data?.data()!['photoUrl'] != null
                                      ? Image.network(
                                          featureSnapShot.data?.data()!['photoUrl'],
                                          height: 25 * 2,
                                          width: 25 * 2,
                                          fit: BoxFit.fill,
                                        )
                                      : Container(),
                                ),
                              ),
                              title: Text(featureSnapShot.data?.data()!['username'] ?? ''),
                              subtitle: Text('${doc.data()['call_type'].toUpperCase()} ${doc.data()['call_by_me'] ? '\u{2197}' : '\u{2199}'} \u{2022} ${formatDateTime(DateTime.fromMillisecondsSinceEpoch(doc['time']))}'),
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

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inHours <= 24) {
      return DateFormat('hh:mm a').format(dateTime);
    } else {
      // Format as date month year
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}
