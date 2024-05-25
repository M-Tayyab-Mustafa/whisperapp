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

class Ringing extends StatefulWidget {
  const Ringing({super.key, required this.mateUid, required this.roomId, required this.fromOverlay});

  final String mateUid;
  final String roomId;
  final bool fromOverlay;

  @override
  State<Ringing> createState() => _RingingState();
}

class _RingingState extends State<Ringing> {
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  final CallController callController = CallController();

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
                        FloatingActionButton(
                          key: GlobalKey(),
                          onPressed: () {
                            callController.closeCall(
                              remoteRenderer: RTCVideoRenderer(),
                              localRenderer: RTCVideoRenderer(),
                              roomId: widget.roomId,
                              customLoader: CustomLoader(),
                            );
                            if (widget.fromOverlay) {
                            } else {
                              Get.back();
                            }
                          },
                          backgroundColor: Colors.redAccent,
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                          ),
                        ),
                        FloatingActionButton(
                          key: GlobalKey(),
                          onPressed: () async {
                            if (widget.fromOverlay) {
                              // SharedPreferences sharedPreference = await SharedPreferences.getInstance();
                              // await sharedPreference.setString('calling', snapShot.data!.data()!['username']);
                              // FirebaseFirestore.instance
                              //     .collection('${snapShot.data!.data()!['username']} calling')
                              //     .doc()
                              //     .set({
                              //   'roomId': widget.roomId,
                              // });
                              await LaunchApp.openApp(
                                androidPackageName: 'com.example.whisperapp',
                              );
                            } else {
                              Navigator.pop(context);
                              Get.to(AnswerCallPage(
                                roomId: widget.roomId,
                                mateName: snapShot.data!.data()!['username'],
                              ))?.then((value) {
                                if (value != null) {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (context) => AlertDialog.adaptive(
                                      title: const Text('Call End'),
                                      content: const Text('Your mate end the Call.'),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              });
                            }
                          },
                          backgroundColor: Colors.green,
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
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
