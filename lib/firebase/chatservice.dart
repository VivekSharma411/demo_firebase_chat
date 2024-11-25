import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createChat(String chatID, List<String> participants) async {
    await _db.collection('chats').doc(chatID).set({
      'participants': participants,
    });
  }

  Future<void> sendMessage(String chatID, String senderID, String content) async {
    await _db.collection('chats').doc(chatID).collection('messages').add({
      'senderID': senderID,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _sendNotification(chatID, senderID, content);

  }
  Future<void> _sendNotification(String chatID, String senderID, String content) async {
    // Get the participants of the chat
    DocumentSnapshot chatDoc = await _db.collection('chats').doc(chatID).get();
    List<String> participants = List.from(chatDoc['participants']);

    // Remove the sender from the list to avoid sending a notification to themselves
    participants.remove(senderID);

    // Fetch FCM tokens for participants
    for (String participantID in participants) {
      DocumentSnapshot userDoc = await _db.collection('chatUsers').doc(participantID).get();
      String? fcmToken = userDoc['fcmToken'];

      if (fcmToken != null) {
        await _sendPushNotification(fcmToken, senderID, content);
      }
    }
  }

  Future<void> _sendPushNotification(String token, String senderID, String content) async {
    const url = 'https://fcm.googleapis.com/v1/projects/fiebasechat-243fd/messages:send';
    final headers = {
      'Content-Type': 'application/json',
    // 'Authorization': 'key=AIzaSyBvyeyem8Gc9aEreryjISL6-zkkSzrNsCg'
      'Authorization': 'Bearer ya29.c.c0ASRK0GbuBUDq5Cd2zwwbjtBSSeTxUxxQ0spylMG64XmrSDemTO6YfvreJ6Xu53z7IgNzhk2-mg1WHJl6InSFvQ35zSuL3oERizIXTWsP2OkHIa0R8ZzLIoOCawO-ixhcZOI9X7GB-t-0WvBDoyRdU9AmDy8oLzUhmyZZT77OEl9Gz7IWEPAcpork4ba_xxbH8T2RCzQiNIQ2-N-Nn-qTQk4HrPLyJmOAr2wa3T03Ck9gdy_UbGK-0_MRasvwp1bN4j7MbG5iTyjLUc2LofSiRMhGgXtV9bDXrSU3IianmomBcl_yD1w_WgfHV-FlWqVN17iWWy0TyowWmip9Mc3A8AsXRrVRlstZeImpbDkNa0vMqwNyOsYq9LQL384PvQXk3Ihq6kZga-6xVkfw63gsXRuiJMFqSgi_q6aZh9nzF4JtIxmzu5d2mBvceR-q2tly6Ufg2Uz9bu0Mr4JXuUd2RUVMRBpxSnqUeq_nsuytiMXg-edsr8ioMc61dX35mnOIR02ScFIfF3pU1muipcbWgzolrp5tbmm43066u_28V99itUMxOIhy9S3rBot2kBk9mt8tfmfRaQJ6zxOtQBlQpBFvqMIkzj0rROcn2OfqYgxrhlVOUjF7iIXexVqr10zj_vBsQWs9Ytzo9__9Wp9w_Y4aSrruo5dVBRa9qRsQwjyzYB2tUr_ZlUmjSqeh47gStfI9hp2z4kWm0daup6r0hJdny9vRzYiUfZmh3Q6VXub2l3971QUZY-JUgJ485MIkwOX8l-JZoB6s8fubSnnt6t-66a3sZgOc2-wIl37o3i-SgFacf-lcSV8oX1c7_1tiqxQs5btBhqjj74xR_xiOi__a5yInjxVbkaQ_kigpZO0OYjB5QehlBMzoJYUsWBUe--jycnUyIXqpYrYeisekd_ki0XF-Woo7WSOJV-rualSgSY7O_6hI9gYh8s_UYmI4Uw2bQbfu30kfOlYW__J4VVrJrOQU9nkZbp135u6lgkJvdQpep-2IzQk', // Replace with your server key
    };

    final body = jsonEncode({
      'to': token,
      'notification': {
        'title': 'My Demo',
        'body': '$content',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK', // Optional: Handle notification click
      },
    });

    await http.post(Uri.parse(url), headers: headers, body: body);
  }

}
