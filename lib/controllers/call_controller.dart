import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../widgets/custom_loader.dart';
import 'chat_controller.dart';
import 'notifications_controller.dart';

typedef PeerConnectionCallBack = void Function(RTCPeerConnection peerConnection);
typedef StreamStateCallback = void Function(MediaStream stream);

class CallController {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302']
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  ChatController chatController = ChatController();

  //Create Call.
  Future<String> createCallRoom({
    required RTCVideoRenderer remoteRenderer,
    required RTCVideoRenderer localRenderer,
    required String mateUid,
    required String callType,
    required CustomLoader customLoader,
    required Function(String) roomid,
    required PeerConnectionCallBack peerConnectionCallBack,
  }) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('callRooms').doc();

    peerConnection = await createPeerConnection(configuration);
    peerConnectionCallBack(peerConnection!);

    registerPeerConnectionListeners(remoteRenderer: remoteRenderer);

    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();

    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    // Further initialization like adding local streams or handling ICE candidates

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    await roomid(roomId);
    // Send a call invitation to friend chat room.

    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("users").doc(mateUid).collection("calls").doc(mateUid).set(
      {
        "calleeUid": currentUserUid,
        "callRoomId": roomId,
        "callType": callType,
        "time": DateTime.now(),
        "callState": "dialing",
      },
    );

    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams.first.getTracks().forEach((track) {
        log(track.toString());
        remoteRenderer.srcObject?.addTrack(track);
      });
    };

    roomRef.snapshots().listen((snapshot) async {
      if (snapshot.data() == null) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null && data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection?.setRemoteDescription(answer);
      }
    });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId;
  }

  //Join Call.

  Future<void> joinCallRoom({
    required String roomId,
    required RTCVideoRenderer remoteRenderer,
    required RTCVideoRenderer localRenderer,
    required PeerConnectionCallBack peerConnectionCallBack,
  }) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('callRooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    peerConnection = await createPeerConnection(configuration);
    peerConnectionCallBack(peerConnection!);

    registerPeerConnectionListeners(remoteRenderer: remoteRenderer);

    localRenderer.srcObject!.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localRenderer.srcObject!);
    });

    var calleeCandidatesCollection = roomRef.collection('calleeCandidates');

    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) {
        return;
      }
      calleeCandidatesCollection.add(candidate.toMap());
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        remoteRenderer.srcObject!.addTrack(track);
      });
    };

    var data = roomSnapshot.data() as Map<String, dynamic>;

    var offer = data['offer'];

    await peerConnection?.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));

    var answer = await peerConnection!.createAnswer();

    await peerConnection!.setLocalDescription(answer);

    Map<String, dynamic> roomWithAnswer = {
      'answer': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    };

    await roomRef.update(roomWithAnswer);

    roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
      for (var document in snapshot.docChanges) {
        var data = document.doc.data() as Map<String, dynamic>;
        peerConnection!.addCandidate(
          RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ),
        );
      }
    });
  }

  // Open Media
  Future<void> openUserMedia({
    required RTCVideoRenderer remoteRenderer,
    required RTCVideoRenderer localRenderer,
    required String callType,
  }) async {
    MediaStream stream;
    if (callType == 'video') {
      stream = await navigator.mediaDevices.getUserMedia(
        {
          'video': true,
          'audio': true,
        },
      );
    } else {
      stream = await navigator.mediaDevices.getUserMedia(
        {
          'video': false,
          'audio': true,
        },
      );
    }
    localRenderer.srcObject = stream;
    remoteRenderer.srcObject = await createLocalMediaStream('key');
  }

  // Register PeerConnection Listeners

  void registerPeerConnectionListeners({
    required RTCVideoRenderer remoteRenderer,
  }) {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('RTCIceGatheringState:: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      log('RTCPeerConnectionState:: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      log('RTCSignalingState:: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      log('RTCIceGatheringState:: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      remoteRenderer.srcObject = stream;
    };
  }

  // Close call.
  Future<void> closeCall({
    required RTCVideoRenderer? remoteRenderer,
    required RTCVideoRenderer localRenderer,
    required String roomId,
    required CustomLoader customLoader,
  }) async {
    List<MediaStreamTrack> tracks = localRenderer.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (remoteRenderer != null) {
      remoteRenderer.srcObject!.getTracks().forEach((track) => track.stop());
    }

    if (peerConnection != null) peerConnection!.close();
    var db = FirebaseFirestore.instance;
    var roomRef = db.collection('callRooms').doc(roomId);

    var calleeCandidates = await roomRef.collection('calleeCandidates').get();
    for (var document in calleeCandidates.docs) {
      document.reference.delete();
    }
    var callerCandidates = await roomRef.collection('callerCandidates').get();
    for (var document in callerCandidates.docs) {
      document.reference.delete();
    }
    await roomRef.delete();
    await customLoader.hideLoader();
    localRenderer.dispose();
    remoteRenderer?.dispose();
  }

  // Add call history to all mates.
  Future<void> addCallHistory(
    String callRoomId,
    String mateUid,
    String callerUid,
    CustomLoader customLoader,
  ) async {
    FirebaseFirestore fireStore = FirebaseFirestore.instance;
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    String dbRef = "users";

    // Set the call history to current user.
    await fireStore.collection('users').doc(currentUserUid).collection("call_history").doc(callRoomId).set(
      {
        "caller": callerUid,
        "time": DateTime.now().toString(),
      },
    );
    // Set the call history to mateUid.
    await fireStore.collection(dbRef).doc(mateUid).collection("calls").doc(callRoomId).set(
      {
        "caller": callerUid,
        "time": DateTime.now().toString(),
      },
    );
    // Hide loader
    customLoader.hideLoader();
  }

  // clear history.
  Future<void> clearCallHistory(CustomLoader customLoader) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    String dbRef = "users";

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(dbRef).doc(currentUserUid).collection("calls");

    QuerySnapshot querySnapshot = await collectionRef.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
    customLoader.hideLoader();
  }
}
