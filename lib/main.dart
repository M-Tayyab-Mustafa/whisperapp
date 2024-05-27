import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart' as background_service;
import 'package:get/get_navigation/get_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notification;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisperapp/routes/route_class.dart';
import 'package:whisperapp/views/calls/ringing.dart';
import 'package:workmanager/workmanager.dart';
import 'controllers/notifications_controller.dart';

//Listen to background Notifications

String initialRoute = RouteClass.splashPage;

Future _firebaseBackgroundNotification(RemoteMessage message) async {
  if (message.notification != null) {}
  try {
    if (message.data['body'].toString() != 'null') {
      await LaunchApp.openApp(
        androidPackageName: 'com.example.whisperapp',
      );
      var preferences = await SharedPreferences.getInstance();
      await preferences.setString('callData', message.data['body']);
    }
  } catch (e) {
    log(e.toString());
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
    }
  });

  //Handle foreground notifications
  FirebaseMessaging.onMessage.listen(
    (RemoteMessage message) async {
      if (message.data['body'].toString() != 'null') {
        var body = jsonDecode(message.data['body']);
        Get.to(
          () => Ringing(
            mateUid: body['mateUid'],
            roomId: body['roomId'],
          ),
        );
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
  initializeService();
  await Permission.ignoreBatteryOptimizations.request();
  await Permission.systemAlertWindow.request();
  await Permission.backgroundRefresh.request();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: RouteClass.routes,
      initialRoute: initialRoute,
      title: 'Whisper',
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const notification.AndroidNotificationChannel channel = notification.AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: notification.Importance.low, // importance must be at low or higher level
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

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log("Native called background task: $task"); //simpleTask will be emitted here.
    return Future.value(true);
  });
}
