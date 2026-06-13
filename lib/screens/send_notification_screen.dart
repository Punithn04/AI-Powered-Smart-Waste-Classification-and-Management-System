import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendNotificationScreen extends StatelessWidget {
  final titleController = TextEditingController();
  final messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Notification",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
              ),
            ),

            SizedBox(height: 12),

            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Message",
              ),
            ),

            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => sendToAll(context),
                icon: Icon(Icons.send),
                label: Text("Send Notification"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void sendToAll(BuildContext context) async {
    final title = titleController.text.trim();
    final message = messageController.text.trim();

    if (title.isEmpty || message.isEmpty) return;

    final users =
        await FirebaseFirestore.instance.collection('users').get();

    for (var user in users.docs) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'userId': user.id,
        'title': title,
        'message': message,
        'type': 'custom',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    titleController.clear();
    messageController.clear();

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Notification sent")));
  }
}