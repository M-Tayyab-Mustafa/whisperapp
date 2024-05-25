import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../views/home/home_page.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;
FlutterLocalNotificationsPlugin localNotification = FlutterLocalNotificationsPlugin();

class NotificationsController {
  static String fcmApiKey =
      "AAAAlZ3op9s:APA91bE7UscbzXR595YKcJhLqX3PkY0qBpfIDlqjKDtDbihi7FJ5OCPQkmWV8JuYoKLyl8GL1-xZcDU0ELPDuc_ge8t99oY5ZUBmBpkMuoKlOKJi3xslRwEE3Ay9z2vynocrvfCzjEWM";

//Initialize notification
  static Future initNotification() async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  }

  //Initialize local notifications
  static Future localNotiInit() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) {},
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    localNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    Get.offAll(() => const HomePage());
  }

  // show a simple notification
  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'WhisperAndroidChannelId',
      'whisper',
      channelDescription: 'Whisper-AProximity chatapp',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      enableVibration: true,
      // sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await localNotification.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  //Send Notification message
  static Future sendMessageNotification({
    required String userToken,
    required String body,
    required String title,
    Map? data,
  }) async {
    try {
      await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmApiKey',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': data ?? 'null',
              'title': title,
            },
            'notification': <String, dynamic>{
              "title": title,
              "body": body,
              "android_channel_id": "WhisperAndroidChannelId",
            },
            "to": userToken,
          },
        ),
      );
    } catch (e) {
      throw "Error $e";
    }
  }
}
