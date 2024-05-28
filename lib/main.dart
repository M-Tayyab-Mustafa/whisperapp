import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'controllers/notifications_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:whisperapp/routes/route_class.dart';
import 'package:whisperapp/views/calls/ringing.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notification;
import 'package:flutter_background_service_android/flutter_background_service_android.dart' as background_service;

Future _firebaseBackgroundNotification(RemoteMessage message) async {
  if (message.data['body'].toString() != 'null') {
    FlutterOverlayWindow.showOverlay(
      height: WindowSize.matchParent,
      overlayTitle: 'Ringing',
      startPosition: const OverlayPosition(0, kToolbarHeight * 0.55),
    );
    await FlutterOverlayWindow.shareData(message.data['body']);
    await LaunchApp.openApp(androidPackageName: 'com.example.whisperapp');
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

  // Notification Tap Controller
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['body'].toString() != 'null') {
      var body = jsonDecode(message.data['body']);
      Get.to(
        () => Ringing(
          mateUid: body['mateUid'],
          roomId: body['roomId'],
        ),
      );
      // FirebaseFirestore.instance.collection('callRooms').doc(body['roomId']).snapshots().listen((doc) {
      // if (doc.get('isCallAttended') == false) {
      // }
      // });
    }
  });

  //Handle foreground notifications
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      log(message.data['body'].toString());
      if (message.data['body'].toString() != 'null') {
        var body = jsonDecode(message.data['body']);
        Get.to(
          () => Ringing(
            mateUid: body['mateUid'],
            roomId: body['roomId'],
          ),
        );
        // FirebaseFirestore.instance.collection('callRooms').doc(body['roomId']).snapshots().listen((doc) {
        // if (doc.get('isCallAttended') == false) {
        // }
        // });
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

  // Initialize Background Service
  initializeService();

  // Request Permissions
  await Permission.unknown.request();
  await Permission.backgroundRefresh.request();
  await Permission.systemAlertWindow.request();
  await Permission.ignoreBatteryOptimizations.request();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Get Overlay Permission
  if (!(await FlutterOverlayWindow.isPermissionGranted())) {
    await FlutterOverlayWindow.requestPermission();
  }

  // Run Application
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

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const notification.AndroidNotificationChannel channel = notification.AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: notification.Importance.low,
  );

  final notification.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      notification.FlutterLocalNotificationsPlugin();
  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const notification.InitializationSettings(
        iOS: notification.DarwinInitializationSettings(),
        android: notification.AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<notification.AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Whisper Application',
      initialNotificationContent: 'Application is running in the background.',
      foregroundServiceNotificationId: math.Random().nextInt(10000),
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final notification.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      notification.FlutterLocalNotificationsPlugin();
  if (service is background_service.AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log("Native called background task: $task"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Padding(
        padding: const EdgeInsets.only(bottom: kToolbarHeight * 0.5),
        child: Scaffold(
          body: StreamBuilder(
            stream: FlutterOverlayWindow.overlayListener,
            builder: (context, snapShot) {
              if (snapShot.hasData) {
                var data = jsonDecode(snapShot.data!);
                return Ringing(
                  mateUid: data['mateUid'],
                  roomId: data['roomId'],
                );
              } else {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      FlutterOverlayWindow.closeOverlay();
                    },
                    child: const Text('Close Overlay'),
                  ),
                );
              }
            },
          ),
        ),
      ),
    ),
  );
}
