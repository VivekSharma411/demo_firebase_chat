import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:random_string/random_string.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(String userID) async {
    String randomName = 'User_${randomString(5)}';
    String? token = await FirebaseMessaging.instance.getToken();

    await _db.collection('chatUsers').doc(userID).set({
      'name': randomName,
      'fcmToken': token,
    });
  }

  Future<void> updateToken(String userID) async {
    String? token = await FirebaseMessaging.instance.getToken();
    await _db.collection('chatUsers').doc(userID).update({
      'fcmToken': token,
    });
  }

  Future<DocumentSnapshot> getUser(String userID) async {
    return await _db.collection('chatUsers').doc(userID).get();
  }
}
