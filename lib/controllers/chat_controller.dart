
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';
import '../widgets/custom_loader.dart';

Codec<String, String> stringToBase64 = utf8.fuse(base64);
class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message.
  Future<String> createChat({
    required List<String> members,
    required String senderId,
    required String messageText,
    required String type,
  }) async {
    try {
      String chatRoomId = const Uuid().v1();

      // Create a new chat model
      final ChatModel newChat = ChatModel(
        chatId: chatRoomId,
        members: members,
        messages: [
          MessageModel(
            sender: senderId,
            messageText: messageText,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            messageType: type,
            room: chatRoomId,
          )
        ],
      );
      Map<String, dynamic> lastMessage = {
        "messageText": messageText,
        "sender": senderId,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "read": false,
        "type": type,
      };

      await _firestore.collection('chats').doc(chatRoomId).set(newChat.toMap());
      await updateLastMessage(chatRoomId, lastMessage);
      return chatRoomId;
    } catch (e) {
      print('Error creating chat: $e');
    }
    return "none";
  }

  //Send a wave
  void sendAWaveToMate({
    required List<String> members,
    required String senderId,
    required String messageText,
    required String type,
  }) async {
    try {
      String chatRoomId = const Uuid().v1();

      // Create a new chat model
      final ChatModel newChat = ChatModel(
        chatId: chatRoomId,
        members: members,
        messages: [
          MessageModel(
              sender: senderId,
              messageText: messageText,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              messageType: type,
              room: "..."
          )
        ],
      );
      Map<String, dynamic> lastMessage = {
        "messageText": messageText,
        "sender": senderId,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "read": false,
        "type": type,
      };

      await _firestore.collection('chats').doc(chatRoomId).set(newChat.toMap());
      await updateLastMessage(chatRoomId, lastMessage);
    } catch (e) {
      print('Error sending wave : $e');
    }
  }

  // Send Message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String messageText,
    required String type,
    required String room,
  }) async {
    try {
      final newMessage = MessageModel(
          sender: senderId,
          messageText: messageText,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          messageType: type,
          room: room
      );

      Map<String, dynamic> lastMessage = {
        "messageText": messageText,
        "sender": senderId,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "read": false,
        "type": type,
      };

      final chatDoc = _firestore.collection('chats').doc(chatId);

      final DocumentSnapshot chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        List<dynamic> currentMessages = chatSnapshot.get("messages");

        currentMessages.add(newMessage.toMap());

        await chatDoc.update({'messages': currentMessages});
      }
      await updateLastMessage(chatId, lastMessage);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Function to delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      final CollectionReference chats =
      FirebaseFirestore.instance.collection('chats');
      final DocumentReference chatDoc = chats.doc(chatId);

      // Fetch the chat document
      final DocumentSnapshot chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        // Get the current list of messages
        List<dynamic> currentMessages = chatSnapshot.get("messages");

        // Find and remove the message by messageId
        currentMessages.removeWhere((message) {
          return message['messageText'] == messageId;
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  //Read all messages
  Future<void> markChatAsRead(String chatId) async {
    try {
      CollectionReference chats =
      FirebaseFirestore.instance.collection('chats');

      // Get the chat document by its ID
      DocumentSnapshot chatSnapshot = await chats.doc(chatId).get();

      if (chatSnapshot.exists) {
        String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

        // Retrieve the 'messages' field, which is an array of messages
        List<dynamic> messages = chatSnapshot['messages'];

        // Update the 'read' field to true for each message where senderId is not equal to currentUserUid
        List updatedMessages = messages.map((message) {
          if (message['sender'] != currentUserUid) {
            message['read'] = true;
          }
          return message;
        }).toList();

        // Update the 'messages' field with the updated messages
        await chats.doc(chatId).update({'messages': updatedMessages});
        //Update last message read
        await updateReadFieldInLastMessage(chatId);

        print('Chat marked as read for non-current user messages.');
      } else {
        print('Chat with ID $chatId does not exist.');
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  //Update last message read
  Future<void> updateReadFieldInLastMessage(String chatId) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      CollectionReference chats =
      FirebaseFirestore.instance.collection('chats');
      DocumentSnapshot chatSnapshot = await chats.doc(chatId).get();

      if (chatSnapshot.exists) {
        Map<String, dynamic>? lastMessage = chatSnapshot['last_message'];

        if (lastMessage != null && lastMessage['sender'] != currentUserId) {
          lastMessage['read'] = true;

          await chats.doc(chatId).update({'last_message': lastMessage});
        }
      }
    } catch (e) {
      print('Error updating "read" field: $e');
    }
  }

  //Update last_message
  Future<void> updateLastMessage(
      String chatId,
      Map<String, dynamic> lastMessage,
      ) async {
    try {
      // Reference to the Firestore collection "chats"
      CollectionReference chats =
      FirebaseFirestore.instance.collection('chats');

      // Update the "last_message" field of the chat document
      await chats.doc(chatId).update({'last_message': lastMessage});
    } catch (e) {
      print("Failed to updated last_message $e");
    }
  }

  //User Status
  Future getUserStatus(String uid) async {
    try {
      var userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (userDoc.exists) {
        String userName = userDoc.data()?['userStatus'];
        return userName;
      } else {
        return "offline";
      }
    } catch (e) {
      return "connecting...";
    }
  }

  // Get user profile pic
  Stream<String> getUserProfilePic(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        String profilePic = userDoc.data()?['photoUrl'];
        return profilePic;
      } else {
        return "none";
      }
    }).handleError((error) {
      return "none";
    });
  }

  // Get user verification badge.
  Stream<String> getUserVerification(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        String isVerified = userDoc.data()!['isVerified'].toString();
        return isVerified;
      } else {
        return "false";
      }
    }).handleError((error) {
      return "false";
    });
  }

  //Delete message dialog
  Future<void> showCustomDialog({
    required BuildContext context,
    required bool isCurrentUser,
    required String message,
    required String chatId,
    required String messageId,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(isCurrentUser ? 'Delete message' : 'Copy message'),
          content: Text(
            isCurrentUser
                ? 'Are you sure you want to delete this message?'
                : 'Message content that you want to copy.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(isCurrentUser ? 'Delete' : 'Copy'),
              onPressed: () async {
                if (isCurrentUser) {
                  //Delete message
                } else {
                  await copyToClipBoard(message);
                }
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeleteDialog({
    required BuildContext context,
    required String chatId,
    required CustomLoader customLoader,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text(
                'Delete',
                style: GoogleFonts.lato(
                  color: Colors.red,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                customLoader.showLoader(context);
                //Delete chat.
                await FirebaseFirestore.instance
                    .collection("chats")
                    .doc(chatId)
                    .delete();
                customLoader.hideLoader();
                Get.snackbar(
                  "Successful!",
                  "Chat has been deleted successfully!",
                );
              },
            ),
          ],
        );
      },
    );
  }

  //Copy to clipboard
  Future copyToClipBoard(String message) async {
    Clipboard.setData(
      ClipboardData(text: message),
    ).then((_) {
      Get.snackbar("Copied", "Message copied successfully!");
    });
  }

// Keep Message
// Delete for Everyone
// Message Opened
}
