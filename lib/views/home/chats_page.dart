import 'package:cached_network_image/cached_network_image.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:whisperapp/webrtc/users.dart';
import 'package:whisperapp/webrtc/video_call_screen.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/sharedPref_controller.dart';
import '../../model/message_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_loader.dart';

import '../chats/chat_room_page.dart';
import 'map.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  SharedPrefController sharedPrefController = Get.put(SharedPrefController());
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  ChatController chatController = Get.put(ChatController());
  CustomLoader customLoader = CustomLoader();

  String getFriendUid(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> chatData, int index) {
    List<String> members = List<String>.from(chatData.data!.docs[index]['members']);
    if (members.length > 1) {
      return members.firstWhere((userId) => userId != currentUserId, orElse: () => 'No friend found');
    }
    return 'No friend found';
  }

  Stream<String> getUserNameByUID(String uid) {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots().map((userDoc) {
      if (userDoc.exists) {
        String username = userDoc.data()?['username'];
        return username;
      } else {
        return "@ChatBot";
      }
    }).handleError((error) {
      return "Error fetching user data";
    });
  }

  Stream<String> getUserStatus(String uid) {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots().map((userDoc) {
      if (userDoc.exists) {
        String userStatus = userDoc.data()?['userStatus'];
        return userStatus;
      } else {
        return "offline";
      }
    }).handleError((error) {
      return "offline";
    });
  }

  Stream<String> getUserProfilePic(String uid) {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots().map((userDoc) {
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

  Stream<String> getUserVerification(String uid) {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots().map((userDoc) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            text: "Chats",
            style: TextStyle(
              color: AppTheme.mainColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              //Find mate
              Get.to(() => const MapScreen(), transition: Transition.cupertino);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              height: 32,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 214, 227, 255),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  "Find",
                  style: GoogleFonts.lato(
                    color: AppTheme.mainColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          //Search chats/mate
          const SizedBox(height: 10),
          //Chats
          Expanded(
            child: StreamBuilder(
              stream: fireStore.collection("chats").where("members", arrayContains: currentUserId).snapshots(),
              builder: (context, chatSnapshot) {
                if (!chatSnapshot.hasData) {
                  return const SizedBox();
                } else if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  // return Center();
                  return Center(
                    child: LoadingAnimationWidget.fourRotatingDots(
                      color: AppTheme.loaderColor,
                      size: 40,
                    ),
                  );
                } else if (chatSnapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => VideoCallScreen()));
                          },
                          child: const Text("Video Call Screen"),
                        ),
                        LottieBuilder.asset(
                          "assets/lottie/chats.json",
                          height: 150,
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: chatSnapshot.data!.docs.length,
                    // shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      List<dynamic> messages = chatSnapshot.data!.docs[index]["messages"];
                      List<MessageModel> unreadMessages = [];

                      for (var messageData in messages) {
                        bool isSenderCurrentUser = messageData["sender"] == currentUserId;

                        if (!isSenderCurrentUser && !messageData["read"]) {
                          MessageModel message = MessageModel(
                              sender: messageData["sender"],
                              messageText: messageData["messageText"],
                              timestamp: messageData["timestamp"],
                              read: messageData["read"],
                              messageType: messageData["messageType"],
                              room: messageData['room'] ?? "");
                          unreadMessages.add(message);
                        }
                      }

                      int unreadMessageCount = unreadMessages.length;

                      return StreamBuilder<String>(
                        stream: getUserNameByUID(getFriendUid(chatSnapshot, index)),
                        builder: (context, friendUidSnapshot) {
                          if (friendUidSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox();
                          } else if (!friendUidSnapshot.hasData) {
                            return const SizedBox();
                          } else {
                            String friendUsername = friendUidSnapshot.data.toString();
                            String initials = friendUsername[0].toUpperCase() +
                                friendUsername[friendUsername.length - 1].toUpperCase();
                            Map<String, dynamic>? lastMessage = chatSnapshot.data!.docs[index]["last_message"];
                            String lastMessageSenderId = lastMessage!["sender"];
                            String messageType = lastMessage["type"];
                            bool isAWave = messageType == "wave" || lastMessage["messageText"] == null;
                            bool isACall = messageType == "call";

                            bool isLastMessageRead() {
                              if (lastMessageSenderId != currentUserId && lastMessage["read"] == true) {
                                return true;
                              }
                              return false;
                            }

                            return ListTile(
                              onLongPress: () {
                                chatController.showDeleteDialog(
                                  context: context,
                                  chatId: chatSnapshot.data!.docs[index].id,
                                  customLoader: customLoader,
                                );
                              },
                              onTap: () {
                                chatController.markChatAsRead(
                                  chatSnapshot.data!.docs[index]["chatId"],
                                );
                                Get.to(
                                  () => ChatRoomPage(
                                    mateName: friendUsername,
                                    mateUid: getFriendUid(chatSnapshot, index),
                                    chatRoomId: chatSnapshot.data!.docs[index]["chatId"],
                                    isNewChat: false,
                                  ),
                                  transition: Transition.cupertino,
                                );
                              },
                              title: Row(
                                children: [
                                  // Friend name
                                  Text(
                                    friendUsername,
                                    style: GoogleFonts.lato(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  // Verification badge
                                  StreamBuilder(
                                    stream: getUserVerification(getFriendUid(chatSnapshot, index)),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox();
                                      } else if (snapshot.data == "true") {
                                        return const Icon(
                                          Icons.verified,
                                          color: AppTheme.mainColor,
                                          size: 16,
                                        );
                                      } else {
                                        return const SizedBox();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              subtitle: isAWave
                                  ? Text(
                                      "A new wave 👋!",
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : isACall
                                      ? Text(
                                          "Call room",
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        )
                                      : Text(
                                          lastMessageSenderId == currentUserId
                                              ? "Me : ${stringToBase64.decode(lastMessage["messageText"])}"
                                              : stringToBase64.decode(lastMessage["messageText"]),
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.lato(
                                            color: isLastMessageRead() == false && lastMessageSenderId != currentUserId
                                                ? AppTheme.loaderColor
                                                : Colors.black54,
                                            fontSize: 12,
                                            fontWeight:
                                                isLastMessageRead() == false && lastMessageSenderId != currentUserId
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                          ),
                                        ),
                              trailing: unreadMessageCount > 0
                                  ? badges.Badge(
                                      badgeAnimation: const badges.BadgeAnimation.fade(),
                                      badgeStyle: const badges.BadgeStyle(
                                        badgeColor: AppTheme.mainColor,
                                      ),
                                      badgeContent: Text(
                                        unreadMessageCount.toString(),
                                        style: GoogleFonts.lato(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                              leading: StreamBuilder<String>(
                                  stream: getUserStatus(getFriendUid(chatSnapshot, index)),
                                  builder: (context, userStatusSnap) {
                                    if (!userStatusSnap.hasData) {
                                      return Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(25),
                                          color: AppTheme.mainColorLight,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (userStatusSnap.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(25),
                                          color: AppTheme.mainColorLight,
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: GoogleFonts.lato(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      bool isUserOnline = userStatusSnap.data! == "online";

                                      return StreamBuilder<String>(
                                        stream: getUserProfilePic(getFriendUid(chatSnapshot, index)),
                                        builder: (context, profileSnap) {
                                          bool hasProfilePicture = profileSnap.hasData && profileSnap.data != "none";
                                          return Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.mainColorLight,
                                            ),
                                            child: Stack(
                                              children: [
                                                hasProfilePicture
                                                    ? ClipOval(
                                                        child: CachedNetworkImage(
                                                          imageUrl: profileSnap.data!,
                                                          fit: BoxFit.cover,
                                                          width: 50,
                                                          height: 50,
                                                          placeholder: (context, url) =>
                                                              Center(child: CircularProgressIndicator()),
                                                          errorWidget: (context, url, error) =>
                                                              Center(child: Icon(Icons.error)),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Text(
                                                          initials,
                                                          style: GoogleFonts.lato(
                                                            fontSize: 16,
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: 15,
                                                    height: 15,
                                                    decoration: BoxDecoration(
                                                      color: isUserOnline ? AppTheme.onlineStatus : Colors.transparent,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Theme.of(context).scaffoldBackgroundColor,
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    }
                                  }),
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),

      //Create message button
      // floatingActionButton: FloatingActionButton(
      //   shape: CircleBorder(),
      //   backgroundColor: AppTheme.mainColor,
      //   child: SvgPicture.asset(
      //     "assets/icons/chat.svg",
      //     color: Colors.white,
      //   ),
      //   onPressed: () {
      //     Get.to(() => const ContactsPage(), transition: Transition.cupertino);
      //   },
      // ),
    );
  }
}
