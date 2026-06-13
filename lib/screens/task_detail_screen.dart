import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> data;

  TaskDetailScreen({required this.taskId, required this.data});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  Future<String> uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('task_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  void showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Upload Image"),
        content: Text("Choose source"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pickAfterImage(ImageSource.camera);
            },
            child: Text("Camera"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pickAfterImage(ImageSource.gallery);
            },
            child: Text("Gallery"),
          ),
        ],
      ),
    );
  }

  Future<void> pickAfterImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() => isUploading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Uploading..."),
          ],
        ),
      ),
    );

    try {
      final imageUrl = await uploadImage(file);

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .update({
        'afterImage': imageUrl,
        'status': 'awaiting',
      });

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed")));
    }

    setState(() => isUploading = false);
  }

  void deleteTask(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .delete();

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Task deleted")));
  }

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Task"),
        content: Text("This cannot be undone. Are you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteTask(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final status = data['status'] ?? "unknown";
    final type = data['type'] ?? "reuse";

    Color statusColor = status == "approved"
        ? Colors.green
        : status == "rejected"
            ? Colors.red
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: Text("Task Detail")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 BEFORE IMAGE CARD
            if (data['beforeImage'] != null &&
                data['beforeImage'].toString().isNotEmpty)
              _imageCard(data['beforeImage'], "Before Image"),

            SizedBox(height: 16),

            // 🔥 AFTER IMAGE
            if (type == 'reuse' && data['afterImage'] != null)
              _imageCard(data['afterImage'], "After Image"),

            SizedBox(height: 16),

            // 🔥 STATUS BADGE
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 16),

            // ✅ APPROVED
            if (status == 'approved') ...[
              _infoCard(
                  "Points Awarded", "${data['points'] ?? 0}", Colors.green),
              if (data['message'] != null)
                _infoCard("Message", data['message'], Colors.green),
            ],

            // ❌ REJECTED
            if (status == 'rejected') ...[
              _infoCard("Rejected", "❌", Colors.red),
              if (data['reason'] != null)
                _infoCard("Reason", data['reason'], Colors.red),
            ],

            SizedBox(height: 20),

            // 📸 UPLOAD BUTTON
            if (type == 'reuse' && data['afterImage'] == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isUploading ? null : () => showImageSourceDialog(),
                  icon: Icon(Icons.upload),
                  label: Text("Upload After Image"),
                ),
              ),

            SizedBox(height: 12),

            // 🗑 DELETE BUTTON
            if (status == 'awaiting' || status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showDeleteDialog(context),
                  icon: Icon(Icons.delete),
                  label: Text("Delete Task"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 IMAGE CARD
  Widget _imageCard(String url, String title) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              url,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.image_not_supported),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 INFO CARD
  Widget _infoCard(String title, String value, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        leading: Icon(Icons.info, color: color),
      ),
    );
  }
}