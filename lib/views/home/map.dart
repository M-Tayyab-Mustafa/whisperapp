import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:whisperapp/model/user_model.dart';

import '../../controllers/chat_controller.dart';
import '../../controllers/notifications_controller.dart';
import '../../controllers/sharedPref_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/custom_icons.dart';
import '../../widgets/custom_loader.dart';
import '../chats/chat_room_page.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {

  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  ChatController chatController = Get.put(ChatController());
  final Location _location = Location();
  final Set<Marker> _markers = {};
  LatLng _currentLatLng = const LatLng(0, 0);
  LatLng _lastKnownLatLng = const LatLng(0, 0);
  bool _isSearching = false;
  String _selectedRange = '100m'; // Default range value
  final List<String> _rangeOptions = ['100m', '200m', '400m', '1000m'];
  List<String> allInterests = [];

  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CustomLoader customLoader = CustomLoader();
  SharedPrefController sharedPrefController = Get.put(SharedPrefController());

  String getFriendUid(
      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> chatData, int index) {
    List<String> members =
    List<String>.from(chatData.data!.docs[index]['members']);
    if (members.length > 1) {
      return members.firstWhere((userId) => userId != currentUserId,
          orElse: () => 'No friend found');
    }
    return 'No friend found';
  }






  Stream<String> getUserStatus(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((userDoc) {
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


  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _fetchAllInterests();
    _fetchUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      var locationData = await _location.getLocation();
      LatLng currentLatLng = LatLng(
          locationData.latitude!, locationData.longitude!);

      // Calculate the distance moved
      double distanceMoved = Geolocator.distanceBetween(
        _lastKnownLatLng.latitude,
        _lastKnownLatLng.longitude,
        currentLatLng.latitude,
        currentLatLng.longitude,
      );

      if (distanceMoved > 20) {
        setState(() {
          _currentLatLng = currentLatLng;
          _lastKnownLatLng = currentLatLng;
        });

        _updateMapLocation();

        // Update the user's location in Firestore
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isNotEmpty) {
          FirebaseFirestore.instance.collection('users').doc(userId).update({
            'latitude': currentLatLng.latitude,
            'longitude': currentLatLng.longitude,
            'location': GeoPoint(
                currentLatLng.latitude, currentLatLng.longitude)
          });
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }


  Future<void> _fetchAllInterests() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection('users')
          .get();
      for (var doc in querySnapshot.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        allInterests.addAll(user.interests as Iterable<String>);
      }
      allInterests = allInterests.toSet().toList(); // Remove duplicates
    } catch (e) {
      print('Error fetching interests: $e');
    }
  }

  Future<void> _updateMapLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
  }

  void _fetchUsers({String searchInterest = ''}) {
    FirebaseFirestore.instance.collection('users')
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        _markers.clear(); // Clear existing markers
      });

      int rangeInMeters = int.parse(_selectedRange.replaceAll('m', ''));
      for (var result in querySnapshot.docs) {
        UserModel user = UserModel.fromMap(
            result.data());
        double distanceInMeters = Geolocator.distanceBetween(
          _currentLatLng.latitude,
          _currentLatLng.longitude,
          user.latitude,
          user.longitude,
        );

        if (distanceInMeters <= rangeInMeters &&
            (searchInterest.isEmpty || user.interests.any((interest) =>
                interest.toLowerCase().contains(
                    searchInterest.toLowerCase())))) {
          _addUserMarker(user, searchInterest);
        }
      }
    });
  }

  Future<BitmapDescriptor> getMarkerImageFromNetwork(String url,
      {int markerSize = 100}) async {
    final http.Response response = await http.get(Uri.parse(url));
    final Uint8List imageData = response.bodyBytes;

    ui.Codec codec = await ui.instantiateImageCodec(imageData);
    ui.FrameInfo fi = await codec.getNextFrame();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder,
        Rect.fromLTWH(0, 0, markerSize.toDouble(), markerSize.toDouble()));
    final Paint paint = Paint()
      ..filterQuality = ui.FilterQuality.high;

    final double radius = markerSize / 2;
    final Offset center = Offset(radius, radius);

    canvas.drawCircle(center, radius, paint);
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius)));

    canvas.drawImageRect(
        fi.image,
        Rect.fromLTWH(
            0, 0, fi.image.width.toDouble(), fi.image.height.toDouble()),
        Rect.fromLTWH(0, 0, markerSize.toDouble(), markerSize.toDouble()),
        paint
    );

    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
        markerSize, markerSize);
    final ByteData? byteData = await markerAsImage.toByteData(
        format: ui.ImageByteFormat.png);
    final Uint8List byteList = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(byteList);
  }

  Future<DocumentSnapshot> fetchUserDetails(String uid) async {
    return FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<void> _addUserMarker(UserModel user, String searchInterest) async {
    double distanceInMeters = Geolocator.distanceBetween(
      _currentLatLng.latitude,
      _currentLatLng.longitude,
      user.latitude,
      user.longitude,
    );

    if (distanceInMeters <= int.parse(_selectedRange.replaceAll('m', '')) &&
        (searchInterest.isEmpty || user.interests.contains(searchInterest))) {
      final BitmapDescriptor markerImage = await getMarkerImageFromNetwork(
          user.photoUrl);
      setState(() {
        _markers.add(
          Marker(
              markerId: MarkerId(user.username),
              position: LatLng(user.latitude, user.longitude),
              // Corrected line
              infoWindow: InfoWindow(title: user.username),
              icon: markerImage,
              onTap: () {
                _showUserProfile(user);
              }
          ),
        );
      });
    }
  }


  // var docData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
  // String username = docData["username"];
  // String mateUid = docData["uid"]; // Changed from "userUid" to "uid"
  // String mateToken =
  // snapshot.data!.docs[index]["fcmToken"];




  Stream<String> getUserNameByUID(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((userDoc) {
      if (userDoc.exists) {
        String userName = userDoc.data()?['userName'];
        return userName;
      } else {
        return "@ChatBot";
      }
    }).handleError((error) {
      return "Error fetching user data";
    });
  }


  void _showUserProfile(UserModel user) {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    if (user.uid == currentUserID) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Notice"),
          content: Text("You can't send a message to yourself."),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        ),
      );
    } else {
      List<String> ids = [user.uid, currentUserID];
      ids.sort();
      String chatRoomId = ids.join('_');
      // Proceed with showing the dialog for other users
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView( // Use SingleChildScrollView to avoid overflow
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl),
                      radius: 50,
                      backgroundColor: Colors.transparent, // Optional: add a background color that matches your theme
                      // Adding a border to the CircleAvatar for a more pronounced look
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blueAccent, // Choose a color that fits your theme
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      user.username,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    if (user.isVerified)
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.blue, size: 20),
                          SizedBox(width: 5),
                          Text("Verified", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    SizedBox(height: 10),
                    Text("Country: ${user.country}"),
                    Text("Province: ${user.province}"),
                    Text("City: ${user.city}"),
                    Text("Date of Birth: ${user.dob}"),
                    Text("Gender: ${user.gender}"),
                    // Enhanced Chip display
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: user.interests.map((interest) => Chip(
                        label: Text(interest),
                        backgroundColor: Colors.lightBlue.shade100, // Custom color
                        avatar: CircleAvatar(
                          backgroundColor: Colors.lightBlue.shade50, // Lighter shade
                          child: Text(interest[0].toUpperCase()), // First letter of the interest
                        ),
                      )).toList(),
                    ),
                    SizedBox(height: 20), // Increased spacing
                    // Your StreamBuilder and ListView.builder code remains the same
                    // Updated ElevatedButton with custom styling
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.message, color: Colors.white),
                        label: Text('Send Message'),
                        onPressed: () {
                          showSendWaveDialog(
                              user.username, user.uid, user.fcmToken
                          ); // Close the dialog
                          // Navigate to ChatRoomPage
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Color(0xFF1E7895), // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    }


  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  Widget _buildSearchBar() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return allInterests.where((String option) {
          return option.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selectedInterest) {
        _searchController.text = selectedInterest;
        _fetchUsers(searchInterest: selectedInterest);
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController, FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search by interests',
            hintStyle: TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic),
            border: InputBorder.none,
          ),
        );
      },
    );
  }


  Widget _buildRangeDropdown() {
    const Color customColor = Color(0xFF1E7895);
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: customColor,
      ),
      child: DropdownButton<String>(
        value: _selectedRange,
        underline: Container(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedRange = newValue!;
          });
          _fetchUsers(searchInterest: _searchController.text);
        },
        items: _rangeOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E7895)),
      ),
    );
  }

  void showSendWaveDialog(String mateName,
      String mateUid,
      String mateToken,) {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(
          "Hi to $mateName \n\n👋\n",
          style: GoogleFonts.lato(
            fontWeight: FontWeight.normal,
          ),
        ),
        content: Text(
          "Do you want to send a wave to user?",
          style: GoogleFonts.lato(),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text(
              "Cancel",
              style: GoogleFonts.lato(
                color: AppTheme.mainColorLight,
              ),
            ),
            onPressed: () {
              Get.back();
            },
          ),
          CupertinoDialogAction(
            child: Text(
              "Send Wave",
              style: GoogleFonts.lato(
                color: AppTheme.mainColor,
              ),
            ),
            onPressed: () async {
              Get.back();
              //send a wave to mate
              waveAtMate(currentUserId, mateUid);
              //send a notification.
              NotificationsController.sendMessageNotification(
                userToken: mateToken,
                body:"A user sent you a wave 😊, Reply them and become friends!",
                title: "Whisper App - Wave 👋",
              );
              Get.snackbar(
                  "Wave sent 😊😊", "You have sent a wave to $mateName");
            },
          ),
        ],
      ),
    );
  }

  void waveAtMate(String currentUserUid, String mateUid) {
    chatController.sendAWaveToMate(
      members: [
        currentUserUid,
        mateUid,
      ],
      senderId: currentUserUid,
      messageText: stringToBase64.encode("👋👋"),
      type: "wave",
    );
  }


  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E7895);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: _isSearching
            ? Row(
          children: <Widget>[
            Expanded(
              child: _buildSearchBar(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
              padding: const EdgeInsets.only(right: 4.0), // Reduce space by adjusting padding here
            ),
          ],
        )
            : const Text('Location'),
        actions: <Widget>[
          // If not searching, show the search icon
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
              padding: EdgeInsets.zero,
            ),
          // The dropdown is always visible; if we're searching, reduce its padding
          Padding(
            padding: EdgeInsets.only(
              right: _isSearching ? 0.0 : 16.0, // Less padding when searching
            ),
            child: Center(child: _buildRangeDropdown()),
          ),
        ],
      ),


  body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: _currentLatLng,
          zoom: 18,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }



}