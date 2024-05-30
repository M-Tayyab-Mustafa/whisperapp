import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:whisperapp/views/calls/call_control_buttons.dart';

import '../../controllers/call_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/notifications_controller.dart';
import '../../creater/webrtc/webrtc_objects.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';

bool cancelByMe = false;

class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    required this.mateUid,
    required this.callType,
    required this.mateName,
  });

  final String mateUid;
  final String mateName;
  final String callType;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  CallController signaling = WebRTCInstances.getSignalInstance();
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  ChatController chatController = Get.put(ChatController());
  CustomLoader customLoader = CustomLoader();
  String currentUser = FirebaseAuth.instance.currentUser!.uid;
  String? mateToken;
  String roomId = "none";

  Duration _ongoingDuration = Duration.zero;
  DateTime? _callStartTime;

  Timer? timer;

  bool isConnected = false;
  bool isFrontCamera = true;

  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    cancelByMe = false;
    KeepScreenOn.turnOn();
    super.initState();
    initRenderer();
  }

  void initRenderer() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    await signaling
        .openUserMedia(
      remoteRenderer: remoteRenderer,
      localRenderer: localRenderer,
      callType: widget.callType,
    )
        .whenComplete(() async {
      await signaling.createCallRoom(
        remoteRenderer: remoteRenderer,
        localRenderer: localRenderer,
        mateUid: widget.mateUid,
        callType: widget.callType,
        customLoader: customLoader,
        roomid: (roomId) {
          this.roomId = roomId;
          setState(() {});
        },
        peerConnectionCallback: (peerConnection) {
          peerConnection.onConnectionState = (RTCPeerConnectionState state) {
            log('RTCPeerConnectionState:: $state');
            if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
              setState(() {
                isConnected = true;
              });
              _callStartTime = DateTime.now();
              timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setState(() {
                  _ongoingDuration = DateTime.now().difference(_callStartTime!);
                });
              });
            }
          };
        },
      );
      await getMateToken();

      await sendCalMessageInvitationCode();
      var db = FirebaseFirestore.instance.collection('callRooms').doc(roomId).snapshots();
      db.listen((event) {
        if (!event.exists) {
          signaling.hangCall(remoteRenderer: remoteRenderer, localRenderer: localRenderer);
          if (!cancelByMe) {
            Get.back();
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) => AlertDialog.adaptive(
                title: const Text('Call End'),
                content: const Text('Your mate end the Call.'),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      cancelByMe = false;
                      Navigator.pop(context);
                    },
                    child: const Text('Ok'),
                  ),
                ],
              ),
            );
          }
        }
      });
    });
  }

  Future<void> getMateToken() async {
    await FirebaseFirestore.instance.collection("users").doc(widget.mateUid).get().then((snapshot) => {mateToken = snapshot["fcmToken"]});
  }

  Future<void> sendCalMessageInvitationCode() async {
    Future.delayed(const Duration(seconds: 2)).then(
      (value) => {
        //send message
        if (roomId != "none")
          {
            // chatController.sendMessage(
            //   chatId: widget.chatRoomId,
            //   senderId: currentUser,
            //   room: roomId,
            //   messageText: stringToBase64
            //       .encode("Hey ${widget.mateName}, Join my call room now & let's talk!, This is my code $roomId"),
            //   type: "call",
            // ),
            //send notification
            if (mateToken != null)
              {
                NotificationsController.sendMessageNotification(
                  userToken: mateToken!,
                  body: "Hey ${widget.mateName}, Join my call room now & let's talk!",
                  title: "Hey ${widget.mateName}",
                  data: {
                    'mateUid': currentUserId,
                    'roomId': roomId,
                  },
                ),
              }
          }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    localRenderer.dispose();
    remoteRenderer.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop:() async =>  false,
      child: Scaffold(
        backgroundColor: AppTheme.callScaffoldColor,
        body: Stack(
          children: [
            // Remote RTCVideoView
            if (widget.callType != 'audio')
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: isConnected
                      ? RTCVideoView(
                          remoteRenderer,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Center(
                          child: Text(
                            'Ringing...',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                ),
              ),

            if (widget.callType == 'audio')
              Center(
                child: FutureBuilder(
                    future: FirebaseFirestore.instance.collection("users").doc(widget.mateUid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: snapshot.data!.data()!['photoUrl'] != null && snapshot.data!.data()!['photoUrl'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(300),
                                  child: Image.network(
                                    snapshot.data!.data()!['photoUrl'],
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.fill,
                                  ),
                                )
                              : SvgPicture.asset("assets/icons/default.svg"),
                        );
                      } else {
                        return Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: SvgPicture.asset("assets/icons/default.svg"),
                        );
                      }
                    }),
              ),
            if (widget.callType == 'audio')
              Padding(
                padding: const EdgeInsets.only(top: 180),
                child: Center(
                  child: Text(
                    widget.mateName,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (widget.callType == 'audio' && !isConnected)
              Padding(
                padding: const EdgeInsets.only(top: 280),
                child: Center(
                  child: Text(
                    'Ringing...',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Top Bar
            Align(
              alignment: Alignment.topCenter,
              child: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(
                    Platform.isAndroid ? Icons.arrow_back : Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                ),
                title: Column(
                  children: [
                    Text(
                      "@${widget.mateName}",
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _ongoingDuration.toString().split('.').first,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
            ),

            //Local RTCVideoView
            if (widget.callType != 'audio' && isConnected)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 100),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    height: 150,
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: RTCVideoView(
                        localRenderer,
                        mirror: isFrontCamera,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ),
              ),

            // Control Buttons
            CallControlButtons(
              customLoader: customLoader,
              signaling: signaling,
              remoteRenderer: remoteRenderer,
              localRenderer: localRenderer,
              roomId: roomId,
              callType: widget.callType,
            ),
            if (widget.callType != 'audio')
              Positioned(
                top: kToolbarHeight + 50,
                right: 20,
                child: SizedBox(
                  height: 45,
                  width: 45,
                  child: IconButton.filled(
                    style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(AppTheme.callButtonsColor),
                    ),
                    onPressed: () {
                      setState(() {
                        isFrontCamera = !isFrontCamera;
                      });
                      localRenderer.srcObject!.getVideoTracks().forEach((track) {
                        Helper.switchCamera(track);
                      });
                    },
                    icon: const Icon(Icons.flip_camera_ios_outlined),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
