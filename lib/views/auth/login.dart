// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:location/location.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:whisperapp/model/user_model.dart';
//
// import '../../controllers/chat_controller.dart';
// import '../../controllers/notifications_controller.dart';
// import '../../controllers/sharedPref_controller.dart';
// import '../../theme/app_theme.dart';
// import '../../utils/custom_icons.dart';
// import '../../widgets/custom_loader.dart';
// import '../chats/chat_room_page.dart';
//
//
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);
//
//   @override
//   State<MapScreen> createState() => MapScreenState();
// }
//
// class MapScreenState extends State<MapScreen> {
//   FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
//   FirebaseStorage firebaseStorage = FirebaseStorage.instance;
//   final Completer<GoogleMapController> _controller = Completer();
//   final TextEditingController _searchController = TextEditingController();
//   ChatController chatController = Get.put(ChatController());
//   final Location _location = Location();
//   Set<Marker> _markers = {};
//   LatLng _currentLatLng = const LatLng(0, 0);
//   LatLng _lastKnownLatLng = const LatLng(0, 0);
//   bool _isSearching = false;
//   String _selectedRange = '100m'; // Default range value
//   List<String> _rangeOptions = ['100m', '200m', '400m', '1000m'];
//   List<String> allInterests = [];
//
//   String currentUserId = FirebaseAuth.instance.currentUser!.uid;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   CustomLoader customLoader = CustomLoader();
//   SharedPrefController sharedPrefController = Get.put(SharedPrefController());
//
//   String getFriendUid(
//       AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> chatData, int index) {
//     List<String> members =
//     List<String>.from(chatData.data!.docs[index]['members']);
//     if (members.length > 1) {
//       return members.firstWhere((userId) => userId != currentUserId,
//           orElse: () => 'No friend found');
//     }
//     return 'No friend found';
//   }
//
//   Stream<String> getUserNameByUID(String uid) {
//     return FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .snapshots()
//         .map((userDoc) {
//       if (userDoc.exists) {
//         String userName = userDoc.data()?['userName'];
//         return userName;
//       } else {
//         return "@ChatMateBot";
//       }
//     }).handleError((error) {
//       return "Error fetching user data";
//     });
//   }
//
//   Stream<String> getUserStatus(String uid) {
//     return FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .snapshots()
//         .map((userDoc) {
//       if (userDoc.exists) {
//         String userStatus = userDoc.data()?['userStatus'];
//         return userStatus;
//       } else {
//         return "offline";
//       }
//     }).handleError((error) {
//       return "offline";
//     });
//   }
//
//   Stream<String> getUserProfilePic(String uid) {
//     return FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .snapshots()
//         .map((userDoc) {
//       if (userDoc.exists) {
//         String profilePic = userDoc.data()?['photoUrl'];
//         return profilePic;
//       } else {
//         return "none";
//       }
//     }).handleError((error) {
//       return "none";
//     });
//   }
//
//   Stream<String> getUserVerification(String uid) {
//     return FirebaseFirestore.instance
//         .collection("users")
//         .doc(uid)
//         .snapshots()
//         .map((userDoc) {
//       if (userDoc.exists) {
//         String isVerified = userDoc.data()!['isVerified'].toString();
//         return isVerified;
//       } else {
//         return "false";
//       }
//     }).handleError((error) {
//       return "false";
//     });
//   }
//
//
//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     _fetchAllInterests();
//     _fetchUsers();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   Future<void> _getUserLocation() async {
//     try {
//       var locationData = await _location.getLocation();
//       LatLng currentLatLng = LatLng(
//           locationData.latitude!, locationData.longitude!);
//
//       // Calculate the distance moved
//       double distanceMoved = Geolocator.distanceBetween(
//         _lastKnownLatLng.latitude,
//         _lastKnownLatLng.longitude,
//         currentLatLng.latitude,
//         currentLatLng.longitude,
//       );
//
//       if (distanceMoved > 20) {
//         setState(() {
//           _currentLatLng = currentLatLng;
//           _lastKnownLatLng = currentLatLng;
//         });
//
//         _updateMapLocation();
//
//         // Update the user's location in Firestore
//         String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
//         if (userId.isNotEmpty) {
//           FirebaseFirestore.instance.collection('users').doc(userId).update({
//             'latitude': currentLatLng.latitude,
//             'longitude': currentLatLng.longitude,
//             'location': GeoPoint(
//                 currentLatLng.latitude, currentLatLng.longitude)
//           });
//         }
//       }
//     } catch (e) {
//       print('Error getting location: $e');
//     }
//   }
//
//
//   Future<void> _fetchAllInterests() async {
//     try {
//       var querySnapshot = await FirebaseFirestore.instance.collection('users')
//           .get();
//       for (var doc in querySnapshot.docs) {
//         UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
//         allInterests.addAll(user.interests as Iterable<String>);
//       }
//       allInterests = allInterests.toSet().toList(); // Remove duplicates
//     } catch (e) {
//       print('Error fetching interests: $e');
//     }
//   }
//
//   Future<void> _updateMapLocation() async {
//     final GoogleMapController controller = await _controller.future;
//     controller.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
//   }
//
//   void _fetchUsers({String searchInterest = ''}) {
//     FirebaseFirestore.instance.collection('users')
//         .snapshots()
//         .listen((querySnapshot) {
//       setState(() {
//         _markers.clear(); // Clear existing markers
//       });
//
//       int rangeInMeters = int.parse(_selectedRange.replaceAll('m', ''));
//       for (var result in querySnapshot.docs) {
//         UserModel user = UserModel.fromMap(
//             result.data() as Map<String, dynamic>);
//         double distanceInMeters = Geolocator.distanceBetween(
//           _currentLatLng.latitude,
//           _currentLatLng.longitude,
//           user.latitude ?? 0.0,
//           user.longitude ?? 0.0,
//         );
//
//         if (distanceInMeters <= rangeInMeters &&
//             (searchInterest.isEmpty || user.interests!.any((interest) =>
//                 interest.toLowerCase().contains(
//                     searchInterest.toLowerCase())))) {
//           _addUserMarker(user, searchInterest);
//         }
//       }
//     });
//   }
//
//   Future<BitmapDescriptor> getMarkerImageFromNetwork(String url,
//       {int markerSize = 100}) async {
//     final http.Response response = await http.get(Uri.parse(url));
//     final Uint8List imageData = response.bodyBytes;
//
//     ui.Codec codec = await ui.instantiateImageCodec(imageData);
//     ui.FrameInfo fi = await codec.getNextFrame();
//
//     double scale = markerSize / fi.image.width;
//
//     final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(pictureRecorder,
//         Rect.fromLTWH(0, 0, markerSize.toDouble(), markerSize.toDouble()));
//     final Paint paint = Paint()
//       ..filterQuality = ui.FilterQuality.high;
//
//     final double radius = markerSize / 2;
//     final Offset center = Offset(radius, radius);
//
//     canvas.drawCircle(center, radius, paint);
//     canvas.clipPath(Path()
//       ..addOval(Rect.fromCircle(center: center, radius: radius)));
//
//     canvas.drawImageRect(
//         fi.image,
//         Rect.fromLTWH(
//             0, 0, fi.image.width.toDouble(), fi.image.height.toDouble()),
//         Rect.fromLTWH(0, 0, markerSize.toDouble(), markerSize.toDouble()),
//         paint
//     );
//
//     final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
//         markerSize, markerSize);
//     final ByteData? byteData = await markerAsImage.toByteData(
//         format: ui.ImageByteFormat.png);
//     final Uint8List byteList = byteData!.buffer.asUint8List();
//
//     return BitmapDescriptor.fromBytes(byteList);
//   }
//
//   Future<DocumentSnapshot> fetchUserDetails(String uid) async {
//     return FirebaseFirestore.instance.collection('users').doc(uid).get();
//   }
//
//   Future<void> _addUserMarker(UserModel user, String searchInterest) async {
//     double distanceInMeters = Geolocator.distanceBetween(
//       _currentLatLng.latitude,
//       _currentLatLng.longitude,
//       user.latitude ?? 0.0,
//       user.longitude ?? 0.0,
//     );
//
//     if (distanceInMeters <= int.parse(_selectedRange.replaceAll('m', '')) &&
//         (searchInterest.isEmpty || user.interests!.contains(searchInterest))) {
//       final BitmapDescriptor markerImage = await getMarkerImageFromNetwork(
//           user.photoUrl);
//       setState(() {
//         _markers.add(
//           Marker(
//               markerId: MarkerId(user.username),
//               position: LatLng(user.latitude, user.longitude),
//               // Corrected line
//               infoWindow: InfoWindow(title: user.username),
//               icon: markerImage,
//               onTap: () {
//                 _showUserProfile(user);
//               }
//           ),
//         );
//       });
//     }
//   }
//
//   void _showUserProfile(UserModel user) {
//     final currentUserID = FirebaseAuth.instance.currentUser!.uid;
//
//     if (user.uid == currentUserID) {
//       // Prevents user from sending a message to themselves
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("You cannot send a message to yourself.")),
//       );
//       return;
//     }
//     List<String> ids = [user.uid, currentUserID];
//     ids.sort(); // Ensures consistency in ID generation
//     String chatRoomId = ids.join('_');
//
//     showDialog(
//
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20.0)),
//           child: Padding(
//             padding: EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Your existing code for dialog content
//                 Expanded(
//                   child: StreamBuilder(
//                     stream: firestore
//                         .collection("users")
//                         .orderBy("userStatus", descending: true)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center();
//                       } else if (snapshot.connectionState ==
//                           ConnectionState.waiting) {
//                         return Center(
//                           child: LoadingAnimationWidget.fourRotatingDots(
//                             color: AppTheme.loaderColor,
//                             size: 40,
//                           ),
//                         );
//                       } else if (snapshot.data!.docs.isEmpty) {
//                         // Display a message when there are no chats.
//                         return Center(
//                           child: Text(
//                             "No mates yet!",
//                             style: GoogleFonts.lato(
//                               fontSize: 14,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         );
//                       } else {
//                         return ListView.builder(
//                           itemCount: snapshot.data!.docs.length,
//                           shrinkWrap: true,
//                           physics: const ClampingScrollPhysics(),
//                           itemBuilder: (context, index) {
//                             var docData = snapshot.data!.docs[index]
//                                 .data() as Map<String, dynamic>;
//
//                             // Change "isOnline" to match your Firestore field
//                             bool isUserOnline = docData["isOnline"] == true;
//
//                             // Correct field names according to your Firestore structure
//                             String username = docData["username"];
//                             String mateUid = docData["uid"]; // Changed from "userUid" to "uid"
//                             String mateToken =
//                             snapshot.data!.docs[index]["fcmToken"];
//                             String currentUserUid = FirebaseAuth.instance
//                                 .currentUser!.uid;
//                             bool hasProfilePicture = docData["photoUrl"] !=
//                                 "none";
//
//                             String initials = username.isNotEmpty
//                                 ? username[0].toUpperCase() +
//                                 username[username.length - 1].toUpperCase()
//                                 : "??"; // Handle case where username might be empty
//
//                             if (mateUid == currentUserUid) {
//                               return const SizedBox(); // Skip current user
//                             }
//
//                             return ListTile(
//                               onTap: () async {
//                                 if (mateUid == currentUserUid) {
//                                   Get.snackbar("No no 😳",
//                                       "You can't send a message to yourself Mate!");
//                                 } else if (username == "chatmate") {
//                                   Get.dialog(
//                                     CupertinoAlertDialog(
//                                       title: Text(
//                                         "Note Mate!",
//                                         style: GoogleFonts.lato(
//                                           fontWeight: FontWeight.normal,
//                                           color: Colors.red,
//                                         ),
//                                       ),
//                                       content: Text(
//                                         "You can't send a wave at the chatMate's official account!",
//                                         style: GoogleFonts.lato(
//                                             color: CupertinoColors.black),
//                                       ),
//                                       actions: <Widget>[
//                                         CupertinoDialogAction(
//                                           child: Text(
//                                             "Understood!",
//                                             style: GoogleFonts.lato(
//                                               color: AppTheme.mainColor,
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             Get.back();
//                                           },
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 } else {
//                                   showSendWaveDialog(
//                                       username, mateUid, mateToken);
//                                 }
//                               },
//                               title: Row(
//                                 children: [
//                                   Text(
//                                     "@${snapshot.data!
//                                         .docs[index]["username"]}",
//                                     style: GoogleFonts.lato(
//                                       color: Colors.black,
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 3),
//
//                                 ],
//                               ),
//
//                               leading: Container(
//                                 height: 50,
//                                 width: 50,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(25),
//                                   color: AppTheme.loaderColor,
//                                 ),
//                                 child: Stack(
//                                   children: [
//                                     hasProfilePicture
//                                         ? CachedNetworkImage(
//                                       imageUrl: snapshot.data!.docs[index]
//                                       ["photoUrl"],
//                                     )
//                                         : Center(
//                                       child: SvgPicture.asset(
//                                           CustomIcons.defaultIcon),
//                                     ),
//                                     if (isUserOnline) ...{
//                                       Positioned(
//                                         bottom: 0,
//                                         right: 0,
//                                         child: Container(
//                                           width: 15,
//                                           height: 15,
//                                           decoration: const BoxDecoration(
//                                             color: AppTheme.onlineStatus,
//                                             shape: BoxShape.circle,
//                                           ),
//                                         ),
//                                       )
//                                     } else
//                                       const SizedBox()
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//                       }
//                     },
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.center,
//                   child: ElevatedButton.icon(
//                     icon: Icon(Icons.message, color: Colors.white),
//                     label: Text('Send Message'),
//                     onPressed: () {
//                       Navigator.of(context).pop(); // Close the dialog
//                       // Replace ChatScreen with ChatRoomPage and ensure you pass the correct parameters
//                       Navigator.of(context).push(
//                         MaterialPageRoute(
//                           builder: (context) =>
//                               ChatRoomPage(
//                                 mateName: user.username,
//                                 mateUid: user.uid,
//                                 chatRoomId: chatRoomId,
//                                 isNewChat: true, // Determine if this should be true or false based on your logic
//                               ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       padding: EdgeInsets.symmetric(
//                           horizontal: 30, vertical: 15),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
//   void _toggleSearch() {
//     setState(() {
//       _isSearching = !_isSearching;
//     });
//   }
//
//   Widget _buildSearchBar() {
//     return Container(
//       padding: EdgeInsets.only(left: 6),
//       margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white, // Background color
//         borderRadius: BorderRadius.circular(30), // Rounded corners
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1), // Shadow color
//             spreadRadius: 1,
//             blurRadius: 10,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: TextField(
//         controller: _searchController,
//         style: TextStyle(color: Colors.black),
//         decoration: InputDecoration(
//           icon: Icon(Icons.search, color: Colors.grey),
//           // Search icon
//           hintText: 'Search by interests',
//           hintStyle: TextStyle(color: Colors.grey),
//           border: InputBorder.none,
//           // Removes underline
//           contentPadding: EdgeInsets.symmetric(vertical: 0), // Adjust padding
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildRangeDropdown() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 12),
//       margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//       decoration: BoxDecoration(
//         color: Colors.white, // Background color
//         borderRadius: BorderRadius.circular(30), // Rounded corners
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1), // Shadow color
//             spreadRadius: 1,
//             blurRadius: 10,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _selectedRange,
//           icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
//           // Dropdown icon
//           onChanged: (String? newValue) {
//             setState(() {
//               _selectedRange = newValue!;
//             });
//             _fetchUsers(searchInterest: _searchController.text);
//           },
//           items: _rangeOptions.map<DropdownMenuItem<String>>((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(
//                 value,
//                 style: TextStyle(color: Colors.black),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   void showSendWaveDialog(String mateName,
//       String mateUid,
//       String mateToken,) {
//     Get.dialog(
//       CupertinoAlertDialog(
//         title: Text(
//           "Hi to $mateName \n\n👋\n",
//           style: GoogleFonts.lato(
//             fontWeight: FontWeight.normal,
//           ),
//         ),
//         content: Text(
//           "Do you want to send a wave to mate?",
//           style: GoogleFonts.lato(),
//         ),
//         actions: <Widget>[
//           CupertinoDialogAction(
//             child: Text(
//               "Cancel",
//               style: GoogleFonts.lato(
//                 color: AppTheme.mainColorLight,
//               ),
//             ),
//             onPressed: () {
//               Get.back();
//             },
//           ),
//           CupertinoDialogAction(
//             child: Text(
//               "Send Wave",
//               style: GoogleFonts.lato(
//                 color: AppTheme.mainColor,
//               ),
//             ),
//             onPressed: () async {
//               Get.back();
//               //send a wave to mate
//               waveAtMate(currentUserId, mateUid);
//               //send a notification.
//               NotificationsController.sendMessageNotification(
//                 userToken: mateToken,
//                 body:
//                 "A mate sent you a wave 😊, Reply them and become friends!",
//                 title: "ChatMate - Wave 👋",
//               );
//               Get.snackbar(
//                   "Wave sent 😊😊", "You have sent a wave to $mateName");
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   void waveAtMate(String currentUserUid, String mateUid) {
//     chatController.sendAWaveToMate(
//       members: [
//         currentUserUid,
//         mateUid,
//       ],
//       senderId: currentUserUid,
//       messageText: "👋👋",
//       type: "wave",
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     const primaryColor = Color(0xFF1E7895);
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         backgroundColor: primaryColor,
//         title: _isSearching
//             ? Row(
//           children: <Widget>[
//             Expanded(
//               child: _buildSearchBar(),
//             ),
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _toggleSearch,
//               padding: EdgeInsets.only(right: 4.0), // Reduce space by adjusting padding here
//             ),
//           ],
//         )
//             : const Text('Location'),
//         actions: <Widget>[
//           // If not searching, show the search icon
//           if (!_isSearching)
//             IconButton(
//               icon: const Icon(Icons.search),
//               onPressed: _toggleSearch,
//               padding: EdgeInsets.zero,
//             ),
//           // The dropdown is always visible; if we're searching, reduce its padding
//           Padding(
//             padding: EdgeInsets.only(
//               right: _isSearching ? 0.0 : 16.0, // Less padding when searching
//             ),
//             child: Center(child: _buildRangeDropdown()),
//           ),
//         ],
//       ),
//
//
//       body: GoogleMap(
//         mapType: MapType.normal,
//         initialCameraPosition: CameraPosition(
//           target: _currentLatLng,
//           zoom: 18,
//         ),
//         markers: _markers,
//         onMapCreated: (GoogleMapController controller) {
//           _controller.complete(controller);
//         },
//       ),
//     );
//   }
//
//
//
// }