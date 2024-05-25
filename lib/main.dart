import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisperapp/routes/route_class.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// import 'package:flutter_background_service/flutter_background_service.dart';

// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:whisperapp/views/calls/ringing.dart';
import 'controllers/notifications_controller.dart';

//Listen to background Notifications
Future _firebaseBackgroundNotification(RemoteMessage message) async {
  if (message.notification != null) {}
  Map<String, dynamic> body = jsonDecode(message.data['body']);
  if (body.toString() != 'null') {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('Ringing', true);
    log('Ringing::::::::::::::::::::::::: ');
    // await LaunchApp.openApp(
    //   androidPackageName: 'com.example.whisperapp',
    // );
    // await FlutterOverlayWindow.showOverlay(positionGravity: PositionGravity.auto, alignment: OverlayAlignment.center);
    // await FlutterOverlayWindow.shareData(body);
  }
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


  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    var body = jsonDecode(message.data['body']);
    if (body != null) {
      if (body.toString() != 'null') {
        Get.to(
          Ringing(
            mateUid: body['mateUid'],
            roomId: body['roomId'],
            fromOverlay: false,
          ),
        );
      }
    }
  });
  //Handle foreground notifications
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      var body = jsonDecode(message.data['body']);
      log('Recived Messag');
      if (body != null) {
        if (body.toString() != 'null') {
          Get.to(
            Ringing(
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
  // Background Service
  // await initializeService();
  // FlutterBackgroundService().invoke("setAsBackground");
  // if (!(await FlutterOverlayWindow.isPermissionGranted())) {
  //   await FlutterOverlayWindow.requestPermission();
  // }
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

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();
//
//   /// OPTIONAL, using custom notification channel id
//   const AndroidNotificationChannel channel = AndroidNotificationChannel(
//     'my_foreground', // id
//     'MY FOREGROUND SERVICE', // title
//     description: 'This channel is used for important notifications.', // description
//     importance: Importance.low,
//   );
//
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   if (Platform.isIOS || Platform.isAndroid) {
//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         iOS: DarwinInitializationSettings(),
//         android: AndroidInitializationSettings('ic_bg_service_small'),
//       ),
//     );
//   }
//
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'my_foreground',
//       initialNotificationTitle: 'whisper Application',
//       initialNotificationContent:
//           'Don\'t Close this notification. If you want to be up to data then don\'t close this notification.',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//     ),
//   );
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();
//
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
//   log('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });
//
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
// }

// @pragma("vm:entry-point")
// void overlayMain() {
//   runApp(
//     MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Container(
//         color: Colors.amber,
//         child: const Text('data'),
//       ),
//     ),
//   );
// }


void startForegroundTask() {
  FlutterForegroundTask.startService(
    notificationTitle: 'Foreground Service',
    notificationText: 'Service is running',
    callback: _callback,
  );
}

void _callback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler implements TaskHandler {

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    // This is where you can initialize any resources you need.
  }

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is where you can perform your background task.
    print('Background task running at: $timestamp');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // This is where you can clean up any resources.
  }

  @override
  void onButtonPressed(String id) {
    // Handle button pressed event.
  }

  @override
  void onNotificationPressed() {
    // Handle notification pressed event.
  }

  @override
  void onNotificationButtonPressed(String id) {
    // TODO: implement onNotificationButtonPressed
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {
    // TODO: implement onRepeatEvent
  }
}

