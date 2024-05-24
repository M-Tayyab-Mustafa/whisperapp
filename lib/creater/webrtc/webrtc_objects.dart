import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:whisperapp/webrtc/signalling.dart';

import '../../controllers/call_controller.dart';

class WebRTCInstances {
  static CallController? instance;

  static CallController getSignalInstance() => instance?? CallController();
}
