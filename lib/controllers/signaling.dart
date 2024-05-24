// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class Signaling {
//   late RTCPeerConnection peerConnection;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   RTCVideoRenderer localRenderer = RTCVideoRenderer();
//   RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
//   StreamSubscription? callSubscription;
//   MediaStream? localStream;
//   String? roomId;
//
//   Signaling() {
//     _initializeRenderers();
//   }
//
//   void _initializeRenderers() async {
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//   }
//
//   Future<void> setupPeerConnection() async {
//     Map<String, dynamic> configuration = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ],
//     };
//     peerConnection = await createPeerConnection(configuration);
//     peerConnection.onIceCandidate = (candidate) {
//       _sendIceCandidate(candidate);
//     };
//     peerConnection.onAddStream = (stream) {
//       remoteRenderer.srcObject = stream;
//     };
//     await _getUserMedia();
//   }
//
//   Future<void> _getUserMedia() async {
//     final constraints = {
//       'audio': true,
//       'video': {
//         'facingMode': 'user',
//       },
//     };
//
//     localStream = await navigator.mediaDevices.getUserMedia(constraints);
//     localRenderer.srcObject = localStream;
//     localStream!.getTracks().forEach((track) {
//       peerConnection.addTrack(track, localStream!);
//     });
//   }
//
//   void createOffer() async {
//     RTCSessionDescription description = await peerConnection.createOffer();
//     await peerConnection.setLocalDescription(description);
//     _sendSessionDescription(description);
//   }
//
//   void createAnswer(String roomId, RTCSessionDescription description) async {
//     this.roomId = roomId;
//     await peerConnection.setRemoteDescription(description);
//     RTCSessionDescription answerDescription = await peerConnection.createAnswer();
//     await peerConnection.setLocalDescription(answerDescription);
//     _sendSessionDescription(answerDescription);
//   }
//
//   void _sendSessionDescription(RTCSessionDescription description) async {
//     if (roomId == null) {
//       print("Error: Room ID is null");
//       return;
//     }
//     var roomRef = firestore.collection('rooms').doc(roomId);
//     var sessionData = {
//       'sdp': description.sdp,
//       'type': description.type,
//     };
//     if (description.type == 'offer') {
//       await roomRef.set({'offer': sessionData});
//     } else {
//       await roomRef.update({'answer': sessionData});
//     }
//   }
//
//   void _sendIceCandidate(RTCIceCandidate candidate) async {
//     if (roomId == null) {
//       print("Error: Room ID is null");
//       return;
//     }
//     await firestore.collection('rooms').doc(roomId).collection('candidates').add({
//       'candidate': candidate.candidate,
//       'sdpMid': candidate.sdpMid,
//       'sdpMLineIndex': candidate.sdpMLineIndex,
//     });
//   }
//
//   Future<void> joinRoom(String roomId) async {
//     this.roomId = roomId;
//     setupPeerConnection();
//     // Listen for offers, answers, and ICE candidates from Firestore
//   }
//
//   Future<void> hangUp() async {
//     if (callSubscription != null) {
//       callSubscription!.cancel();
//     }
//     if (localStream != null) {
//       localStream!.getTracks().forEach((track) {
//         track.stop();
//       });
//     }
//     if (peerConnection != null) {
//       peerConnection.close();
//     }
//     localRenderer.dispose();
//     remoteRenderer.dispose();
//     // Optionally: Clear call data from Firestore
//   }
// }
