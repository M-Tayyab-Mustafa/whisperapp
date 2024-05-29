import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import '../../controllers/call_controller.dart';
import '../../creater/webrtc/webrtc_objects.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';
import 'call_control_buttons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'call_page.dart';

class AnswerCallPage extends StatefulWidget {
  const AnswerCallPage({
    Key? key,
    required this.roomId,
    required this.mateName,
  }) : super(key: key);

  final String roomId;
  final String mateName;

  @override
  State<AnswerCallPage> createState() => _AnswerCallPageState();
}

class _AnswerCallPageState extends State<AnswerCallPage> {
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
  CallController signaling = WebRTCInstances.getSignalInstance();
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  CustomLoader customLoader = CustomLoader();
  String? callType;

  bool isConnected = false;

  Duration _ongoingDuration = Duration.zero;
  DateTime? _callStartTime;
  Timer? timer;

  @override
  void initState() {
    cancelByMe = false;
    KeepScreenOn.turnOn();
    super.initState();
    initRenderers();
    var db = FirebaseFirestore.instance.collection('callRooms').doc(widget.roomId).snapshots();
    db.listen((event) async {
      if (!event.exists) {
        signaling.hangCall(remoteRenderer: remoteRenderer, localRenderer: localRenderer);
        if (!cancelByMe) {
          timer?.cancel();
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog.adaptive(
              title: const Text('Call End'),
              content: const Text('Your mate end the Call.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    cancelByMe = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'),
                ),
              ],
            ),
          );
          Get.back();
          if (await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.closeOverlay();
          }
        }
      }
    });
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    signaling.peerConnection?.onIceConnectionState = (state) {
      setState(() {});
    };
    await getCallRoom();
  }

  Future<void> getCallRoom() async {
    try {
      final doc = await fireStore.collection("users").doc(currentUserUid).collection("calls").doc(currentUserUid).get();
      if (doc.exists) {
        callType = doc.data()?["callType"];
        setState(() {});
        await initializeMedia();
      } else {
        log("No call data found.");
        // Optionally, handle no call data found (e.g., show error or close the page)
      }
    } catch (e) {
      log("Error fetching call data: $e");
      // Optionally, handle errors (e.g., show error message)
    }
  }

  Future<void> initializeMedia() async {
    if (callType != null) {
      await signaling.openUserMedia(
        remoteRenderer: remoteRenderer,
        localRenderer: localRenderer,
        callType: callType!,
      );
      await signaling.joinCallRoom(
        remoteRenderer: remoteRenderer,
        localRenderer: localRenderer,
        roomId: widget.roomId,
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
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    remoteRenderer.dispose();
    localRenderer.dispose();
    KeepScreenOn.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.callScaffoldColor,
      body: Stack(
        children: [
          // Remote RTCVideoView
          if (callType != 'audio')
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
                          'Joining...',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
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
                onPressed: () async {
                  if (await FlutterOverlayWindow.isActive()) {
                    FlutterOverlayWindow.closeOverlay();
                  }
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

          if (callType == 'audio')
            Center(
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: SvgPicture.asset(
                  "assets/icons/default.svg",
                ),
              ),
            ),
          if (callType == 'audio')
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
          if (callType == 'audio' && !isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 280),
              child: Center(
                child: Text(
                  'Joining...',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          //Local RTCVideoView
          if (callType != 'audio' && isConnected)
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
            roomId: widget.roomId,
            callType: callType ?? '',
          ),
          if (callType != 'audio')
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
    );
  }
}
