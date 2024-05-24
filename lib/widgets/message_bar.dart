import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../controllers/notifications_controller.dart';
import '../theme/app_theme.dart';

class CustomMessageBar extends StatefulWidget {
  final Color messageBarColor;
  final String messageBarHintText;
  final TextStyle messageBarHintStyle;
  final TextStyle textFieldTextStyle;
  final Color sendButtonColor;
  final FocusNode focusNode;
  final String currentUser;
  final String chatRoomId;
  final String mateName;
  final String mateToken;
  final bool isNewChat;
  final String mateUid;

  CustomMessageBar({
    this.messageBarColor = const Color(0xffF4F4F5),
    this.sendButtonColor = Colors.blue,
    this.messageBarHintText = "Type your message here",
    this.messageBarHintStyle = const TextStyle(fontSize: 16),
    this.textFieldTextStyle = const TextStyle(color: Colors.black),
    required this.mateUid,
    required this.focusNode,
    required this.currentUser,
    required this.chatRoomId,
    required this.mateName,
    required this.mateToken,
    required this.isNewChat,
  });

  @override
  State<CustomMessageBar> createState() => _CustomMessageBarState();
}

class _CustomMessageBarState extends State<CustomMessageBar> {
  final TextEditingController _textController = TextEditingController();
  ChatController chatController = Get.put(ChatController());
  String rawMessageText = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.messageBarColor,
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: () async {},
            child: SvgPicture.asset(
              "assets/icons/emoji.svg",
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              focusNode: widget.focusNode,
              controller: _textController,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              onChanged: (value) {
                setState(() {});
                rawMessageText = value;
              },
              style: widget.textFieldTextStyle,
              cursorColor: AppTheme.mainColor,
              decoration: InputDecoration(
                hintText: widget.messageBarHintText,
                hintMaxLines: 1,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                hintStyle: widget.messageBarHintStyle,
                fillColor: Colors.white,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: Colors.white,
                    width: 0.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(
                    color: Colors.black26,
                    width: 0.2,
                  ),
                ),
              ),
            ),
          ),
          _textController.text.trim().isEmpty
              ? IconButton(
                  onPressed: () {
                    if (_textController.text.trim() != '') {
                      _textController.text = '';
                    }
                  },
                  icon: SvgPicture.asset(
                    "assets/icons/send.svg",
                    color: AppTheme.mainColor,
                  ),
                )
              : IconButton(
                  onPressed: () async {
                    if (_textController.text.trim() != '') {
                      widget.isNewChat
                          ? chatController.createChat(
                              members: [
                                widget.currentUser,
                                widget.mateUid ?? "",
                              ],
                              senderId: widget.currentUser,
                              messageText: stringToBase64.encode(_textController.text.trim()),
                              type: "text",
                            )
                          :
                          //send message
                          chatController.sendMessage(
                              chatId: widget.chatRoomId,
                              senderId: widget.currentUser,
                              messageText: stringToBase64.encode(_textController.text.trim()),
                              type: "text",
                              room: "",
                            );
                    }
                    _textController.text = '';
                    //send notifcation
                    await NotificationsController.sendMessageNotification(
                      userToken: widget.mateToken,
                      body: rawMessageText.trim(),
                      title: widget.mateName,
                    );
                  },
                  //Send file
                  icon: Transform.rotate(
                    angle: 45 * (3.141592653589793 / 180),
                    child: SvgPicture.asset(
                      "assets/icons/send.svg",
                      color: AppTheme.mainColor,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
