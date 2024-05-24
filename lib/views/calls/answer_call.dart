import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/call_controller.dart';
import '../../creater/webrtc/webrtc_objects.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';
import 'call_control_buttons.dart';
import 'call_page.dart';

class AnswerCallPage extends StatefulWidget {
  const AnswerCallPage({Key? key, required this.roomId, required this.mateName}) : super(key: key);

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
    super.initState();
    initRenderers();
  }

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    signaling.peerConnection?.onIceConnectionState = (state) {
      setState(() {});
    };
    await getCallRoom();
  }

  _peerConnectionCallBack(RTCPeerConnection peerConnection) {
    peerConnection.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _callStartTime = DateTime.now();
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _ongoingDuration = DateTime.now().difference(_callStartTime!);
          });
        });
        localRenderer.srcObject!.getTracks().forEach((track) {
          log('Adding Local Track');
          peerConnection.addTrack(track, localRenderer.srcObject!);
        });
        setState(() {
          isConnected = true;
        });
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        timer?.cancel();
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
                  Get.back();
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        timer?.cancel();
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('Connection Error'),
            content: const Text('Unable to Connect. Please Check you internet Connection and then try again.'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  signaling.closeCall(
                      remoteRenderer: remoteRenderer,
                      localRenderer: localRenderer,
                      roomId: widget.roomId,
                      customLoader: customLoader);
                  Get.back();
                },
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
    };

    peerConnection.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
      setState(() {});
    };
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
      await signaling.openUserMedia(remoteRenderer: remoteRenderer, localRenderer: localRenderer, callType: callType!);
      await signaling
          .joinCallRoom(
            remoteRenderer: remoteRenderer,
            localRenderer: localRenderer,
            roomId: widget.roomId,
            peerConnectionCallBack: _peerConnectionCallBack,
          )
          .whenComplete(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    remoteRenderer.dispose();
    localRenderer.dispose();
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
            renderVideoOrText(
              remoteRender: remoteRenderer,
              mateName: widget.mateName,
              connected: isConnected,
              title: 'Calling',
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
          )
        ],
      ),
    );
  }
}
