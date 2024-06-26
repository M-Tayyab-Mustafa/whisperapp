import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisperapp/views/calls/call_control_buttons.dart';

import '../../controllers/call_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/notifications_controller.dart';
import '../../creater/webrtc/webrtc_objects.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';

class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    required this.mateUid,
    required this.callType,
    required this.mateName,
    required this.chatRoomId,
  });

  final String mateUid;
  final String mateName;
  final String callType;
  final String chatRoomId;

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

  @override
  void initState() {
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
      );
      await getMateToken();
      await sendCalMessageInvitationCode();
      _callStartTime = DateTime.now();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _ongoingDuration = DateTime.now().difference(_callStartTime!);
        });
      });
    });
  }

  Future<void> getMateToken() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.mateUid)
        .get()
        .then((snapshot) => {mateToken = snapshot["fcmToken"]});
  }

  Future<void> sendCalMessageInvitationCode() async {
    Future.delayed(const Duration(seconds: 5)).then(
      (value) => {
        //send message
        if (roomId != "none")
          {
            chatController.sendMessage(
              chatId: widget.chatRoomId,
              senderId: currentUser,
              room: roomId,
              messageText: stringToBase64
                  .encode("Hey ${widget.mateName}, Join my call room now & let's talk!, This is my code $roomId"),
              type: "call",
            ),
            //send notification
            if (mateToken != null)
              {
                NotificationsController.sendMessageNotification(
                  userToken: mateToken!,
                  body: "Hey ${widget.mateName}, Join my call room now & let's talk!",
                  title: "Hey ${widget.mateName}",
                  data: {
                    'mateUid': widget.mateUid,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: RTCVideoView(
                  remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                    _ongoingDuration.toString(),
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
          if (widget.callType != 'audio')
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
                      mirror: true,
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
          )
        ],
      ),
    );
  }
}
