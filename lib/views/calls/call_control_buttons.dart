import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:whisperapp/controllers/call_controller.dart';
import 'package:whisperapp/widgets/custom_loader.dart';

import '../../theme/app_theme.dart';
import 'call_page.dart';

class CallControlButtons extends StatefulWidget {
  const CallControlButtons({
    super.key,
    required this.customLoader,
    required this.signaling,
    required this.remoteRenderer,
    required this.localRenderer,
    required this.roomId,
    required this.callType,
  });

  final CustomLoader customLoader;
  final CallController signaling;
  final RTCVideoRenderer remoteRenderer;
  final RTCVideoRenderer localRenderer;
  final String roomId;
  final String callType;

  @override
  State<CallControlButtons> createState() => _CallControlButtonsState();
}

class _CallControlButtonsState extends State<CallControlButtons> {
  bool onSpeaker = true;
  bool notMute = true;
  bool openCamera = true;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Video Pause
            if (widget.callType == 'video')
              SizedBox(
                height: 60,
                width: 60,
                child: IconButton.filled(
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(AppTheme.callButtonsColor),
                  ),
                  onPressed: () {
                    openCamera = !openCamera;
                    setState(() {});
                    widget.localRenderer.srcObject!.getVideoTracks().forEach((element) {
                      element.enabled = openCamera;
                    });
                  },
                  icon: openCamera ? const Icon(Icons.videocam) : const Icon(Icons.videocam_off_outlined),
                ),
              ),

            //Sound high
            SizedBox(
              height: 60,
              width: 60,
              child: IconButton.filled(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(AppTheme.callButtonsColor),
                ),
                onPressed: () {
                  onSpeaker = !onSpeaker;
                  setState(() {});
                  widget.localRenderer.srcObject!.getAudioTracks().forEach((element) {
                    element.enableSpeakerphone(onSpeaker);
                  });
                },
                icon: onSpeaker
                    ? SvgPicture.asset(
                        "assets/icons/soundOn.svg",
                        color: Colors.white,
                      )
                    : const Icon(Icons.phone),
              ),
            ),

            //mute
            SizedBox(
              height: 60,
              width: 60,
              child: IconButton.filled(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    AppTheme.callButtonsColor,
                  ),
                ),
                onPressed: () {
                  notMute = !notMute;
                  setState(() {});
                  widget.localRenderer.srcObject!.getAudioTracks().forEach((element) {
                    element.enabled = notMute;
                  });
                },
                icon: notMute
                    ? SvgPicture.asset(
                        "assets/icons/audioOn.svg",
                        color: Colors.white,
                      )
                    : const Icon(Icons.mic_off_rounded),
              ),
            ),

            //End call
            SizedBox(
              height: 60,
              width: 60,
              child: IconButton.filled(
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll(
                    AppTheme.endCallButtonColor,
                  ),
                ),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return CupertinoAlertDialog(
                        title: const Text("End Call"),
                        content: const Text("Are you sure you want to end this call?"),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          CupertinoDialogAction(
                            child: const Text(
                              "End Call",
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              cancelByMe = true;
                              await widget.customLoader.showLoader(dialogContext);
                              await widget.signaling
                                  .closeCall(
                                customLoader: widget.customLoader,
                                remoteRenderer: widget.remoteRenderer,
                                localRenderer: widget.localRenderer,
                                roomId: widget.roomId,
                              )
                                  .whenComplete(() async {
                                if (await FlutterOverlayWindow.isActive()) {
                                  Get.back();
                                  await FlutterOverlayWindow.closeOverlay();
                                } else {
                                  Get.back();
                                  Get.back();
                                }
                              });
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: SvgPicture.asset(
                  "assets/icons/endcall.svg",
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
