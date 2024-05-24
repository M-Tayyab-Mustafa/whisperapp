import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisperapp/controllers/chat_controller.dart';
import 'package:whisperapp/views/calls/call_page.dart';

import '../theme/app_theme.dart';
import '../views/calls/answer_call.dart';

class MyChatBubble extends StatelessWidget {
  const MyChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    required this.type,
    required this.roomId,
    required this.mateName,
  });

  final String message;
  final bool isSender;
  final String type;
  final String? roomId;
  final String mateName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        type == "wave" && isSender == true
            ? BubbleNormal(
                text: stringToBase64.decode(message) ,
                isSender: isSender,
                //color: Color(0xFF1B97F3),
                color: Colors.white,
                tail: true,
                //seen: isRead,
                //sent: isSent,
                textStyle: GoogleFonts.lato(
                  fontSize: 18,
                  color: Colors.white,
                ),
              )
            : type == "wave" && isSender == false
                ? BubbleNormal(
                    text: stringToBase64.decode(message),
                    isSender: isSender,
                    color: Colors.transparent,
                    textStyle: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    tail: true,
                  )
                : type == "text" && isSender == true
                    ? BubbleNormal(
                        text: stringToBase64.decode(message),
                        isSender: isSender,
                        //color: Color(0xFF1B97F3),
                        color: AppTheme.mainColor,
                        tail: true,
                        //seen: isRead,
                        //sent: isSent,
                        textStyle: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
                    : BubbleNormal(
                        text: stringToBase64.decode(message),
                        isSender: isSender,
                        color: const Color(0xFFE8E8EE),
                        textStyle: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        tail: true,
                      ),
        type == "call" && isSender == false
            ? StreamBuilder(
                stream: FirebaseFirestore.instance.collection('callRooms').doc(roomId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && (snapshot.data as DocumentSnapshot).exists) {
                    return ElevatedButton(
                        onPressed: () {
                          Get.to(AnswerCallPage(
                            roomId: roomId!,
                            mateName: mateName,
                          ));
                        },
                        child: const Text("Join Call"));
                  } else {
                    return const Text('');
                  }
                })
            : const Text(""),
      ],
    );
  }

  bool isUrl(String text) {
    Uri uri = Uri.parse(text);
    return uri.scheme.isNotEmpty;
  }
}
