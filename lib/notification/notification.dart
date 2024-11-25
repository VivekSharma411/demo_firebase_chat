import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notification  {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // Constructor
  Notification() {
    initLocalNotification(); // Initialize local notifications here
    getRefreshToken(); // Listen for token refreshes
  }



  void requestNotificationPermission() async{
    NotificationSettings notificationSettings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      carPlay: true,
      sound: true,
      provisional: true,
      criticalAlert: true,

    );
    if(notificationSettings.authorizationStatus == AuthorizationStatus.authorized){


    }else if (notificationSettings.authorizationStatus ==AuthorizationStatus.provisional){

    }else{
     // AppSettings.openAppSettings();


    }
  }

  Future<String> getDeviceToken() async{
    String? token = await messaging.getToken();
    print("Here is Device Token ::: >>>> $token");
    return token!;
  }

  /// If Token Is Expired
  void getRefreshToken() async{
    messaging.onTokenRefresh.listen((event){
      event.toString();
    });


    ///Handel If APP Is Already Open
    ///



    Future<void> showNotification(RemoteMessage message) async{

      //Android Notification
      AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
          Random.secure().nextInt(1000).toString(),
          "High Importance Notification",
          importance:  Importance.max
      );

      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
          androidNotificationChannel.id.toString(),
          androidNotificationChannel.name.toString(),
          channelDescription: "your channel description",
          importance: Importance.high,
          priority:  Priority.high,
          ticker: 'ticker'
      );
      const DarwinNotificationDetails darwinInitializationDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true
      );
      NotificationDetails notificationDetails =NotificationDetails(
          android:  androidNotificationDetails,
          iOS: darwinInitializationDetails
      );
      Future.delayed(Duration.zero,(){
        flutterLocalNotificationsPlugin.show(1,
            message.notification?.title.toString(),
            message.notification?.body.toString(), notificationDetails);
      });

    }

    FirebaseMessaging.onMessage.listen((receiveNotification) {
      showNotification(receiveNotification);
    });
  }

  void initLocalNotification() async{

    var androidInitialization = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitialization = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (payload){

        }
    );

  }




}
