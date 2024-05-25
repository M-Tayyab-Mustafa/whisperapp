import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisperapp/routes/route_class.dart';

// import 'package:flutter_background_service/flutter_background_service.dart';

// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:whisperapp/views/calls/ringing.dart';
import 'controllers/notifications_controller.dart';

//Listen to background Notifications
Future _firebaseBackgroundNotification(RemoteMessage message) async {
  if (message.notification != null) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  //Initialize Notifications
  await NotificationsController.initNotification();
  await NotificationsController.localNotiInit();

  //Initialize background notifications.
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundNotification);

  //Handle foreground notifications
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      var body = jsonDecode(message.data['body']);
      log('Received Message');
      if (body != null) {
        if (body.toString() != 'null') {
          Get.to(
            () => Ringing(
              mateUid: body['mateUid'],
              roomId: body['roomId'],
              fromOverlay: false,
            ),
          );
        }
      } else {
        if (message.notification != null) {
          String notificationPayLoad = jsonEncode(message.data);
          NotificationsController.showSimpleNotification(
            title: message.notification!.title!,
            body: message.notification!.body!,
            payload: notificationPayLoad,
          );
        }
      }
    },
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: RouteClass.routes,
      initialRoute: RouteClass.splashPage,
      title: 'Whisper',
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}
