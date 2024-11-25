import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String currentUserID;
  String chatID = "global_chat"; // Use a fixed chat ID for group chat
  List<String> participants = [];

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _initializeFCM();
    _setupForegroundMessaging();
  }
  void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message title: ${message.notification?.title}');
        print('Message body: ${message.notification?.body}');
        // Display a dialog or notification in the app if desired
      }
    });
  }


  void _initializeUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserID = user.uid;
      });
      _saveUserToFirestore(user.uid);
    }
  }

  void _initializeFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print("Device Token: $token");

    if (token != null && currentUserID.isNotEmpty) {
      await _db.collection('chatUsers').doc(currentUserID).update({'fcmToken': token});
    }
  }

  void _saveUserToFirestore(String uid) async {
    DocumentSnapshot userDoc = await _db.collection('chatUsers').doc(uid).get();
    if (!userDoc.exists) {
      await _db.collection('chatUsers').doc(uid).set({
        'name': 'User_${uid.substring(0, 5)}', // Create a random username
        'fcmToken': '',
      });
    }
  }


  void _showGroupChatDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select or Create Group Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Here you can add buttons or a list to select/create groups
              ListTile(
                title: Text('Group 1'),
                onTap: () {
                  Navigator.of(context).pop();
                  _switchGroupChat('group1'); // Switch to Group 1
                },
              ),
              ListTile(
                title: Text('Group 2'),
                onTap: () {
                  Navigator.of(context).pop();
                  _switchGroupChat('group2'); // Switch to Group 2
                },
              ),
              // You can add more groups or a button to create a new group
              ListTile(
                title: Text('Create New Group'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Handle new group creation logic
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _switchGroupChat(String groupId) {
    setState(() {
      chatID = groupId; // Update chatID to the selected group
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            onPressed: _showGroupChatDialog, // Show group chat options
          ),
        ],
      ),      body: Column(
        children: [
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder(
      stream: _db
          .collection('chats')
          .doc(chatID)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        return ListView(
          reverse: true,
          children: snapshot.data!.docs.map((doc) {
            return _buildMessageItem(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    bool isCurrentUser = doc['senderID'] == currentUserID;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc['senderName'] ?? 'Unknown',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              doc['content'],
              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _db.collection('chats').doc(chatID).collection('messages').add({
      'content': _messageController.text.trim(),
      'senderID': currentUserID,
      'senderName': 'User_${currentUserID.substring(0, 5)}',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }
}
