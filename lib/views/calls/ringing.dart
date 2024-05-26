import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisperapp/controllers/call_controller.dart';
import 'package:whisperapp/views/calls/answer_call.dart';
import 'package:whisperapp/widgets/custom_loader.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

import '../../creater/webrtc/webrtc_objects.dart';
import 'call_page.dart';

class Ringing extends StatefulWidget {
  const Ringing({super.key, required this.mateUid, required this.roomId});

  final String mateUid;
  final String roomId;

  @override
  State<Ringing> createState() => _RingingState();
}

class _RingingState extends State<Ringing> {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  final CallController signalling = WebRTCInstances.getSignalInstance();
  final CustomLoader customLoader = CustomLoader();

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer.playRingtone(looping: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
            future: fireStore.collection("users").doc(widget.mateUid).get(),
            builder: (context, snapShot) {
              if (snapShot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(1000),
                        child: Image.network(
                          snapShot.data!.data()!['photoUrl'],
                          height: 50 * 2,
                          width: 50 * 2,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Text('${snapShot.data!.data()!['username']} Calling...'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: IconButton.filled(
                            style: const ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                Colors.redAccent,
                              ),
                            ),
                            onPressed: () async {
                              cancelByMe = true;
                              customLoader.showLoader(context);
                              signalling.closeCall(
                                remoteRenderer: RTCVideoRenderer(),
                                localRenderer: RTCVideoRenderer(),
                                roomId: widget.roomId,
                                customLoader: customLoader,
                              );
                              Get.back();
                            },
                            icon: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: IconButton.filled(
                            style: const ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                Colors.green,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              Get.to(() => AnswerCallPage(
                                    roomId: widget.roomId,
                                    mateName: snapShot.data!.data()!['username'],
                                  ));
                            },
                            icon: const Icon(
                              Icons.call,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }

  @override
  void dispose() {
    FlutterRingtonePlayer.stop();
    super.dispose();
  }
}
