import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final String apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';

  // =========================
  // 🔥 LOGIC (UNCHANGED)
  // =========================

  Future<String?> validateTask(String label) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();

    int todayCount = 0;
    int sameLabelCount = 0;
    DateTime? lastTaskTime;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final taskLabel = data['label'];

      if (createdAt == null) continue;

      if (createdAt.day == now.day &&
          createdAt.month == now.month &&
          createdAt.year == now.year) {
        todayCount++;

        if (taskLabel == label) sameLabelCount++;
      }

      if (lastTaskTime == null || createdAt.isAfter(lastTaskTime)) {
        lastTaskTime = createdAt;
      }
    }

    if (lastTaskTime != null &&
        now.difference(lastTaskTime).inMinutes < 5) {
      return "⏳ Wait 5 minutes before next task";
    }

    if (todayCount >= 5) {
      return "🚫 Daily limit reached (5 tasks)";
    }

    if (sameLabelCount >= 3) {
      return "⚠ Same item limit reached (3 per day)";
    }

    return null;
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      setState(() {
        _image = imageFile;
      });

      await detectImage(imageFile);
    }
  }

  void showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Processing...")),
          ],
        ),
      ),
    );
  }

  void hideLoading() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> detectImage(File image) async {
    try {
      showLoading();

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
            "https://vision.googleapis.com/v1/images:annotate?key=$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "LABEL_DETECTION", "maxResults": 5}
              ]
            }
          ]
        }),
      );

      hideLoading();

      if (response.statusCode != 200) {
        showError("API Error: ${response.body}");
        return;
      }

      final data = jsonDecode(response.body);
      final responses = data["responses"];

      if (responses == null || responses.isEmpty) {
        showError("No response from AI");
        return;
      }

      final labels = responses[0]["labelAnnotations"];

      if (labels != null && labels.isNotEmpty) {
        List<String> detected = labels
            .map<String>((e) => e["description"].toString().toLowerCase())
            .toList();

        handleResult(detected);
      } else {
        showError("Could not detect item");
      }
    } catch (e) {
      hideLoading();
      showError("Error: $e");
    }
  }

  void handleResult(List<String> labels) async {
    String name = labels.first;

    if (name.contains("battery") ||
        name.contains("electronic") ||
        name.contains("mobile") ||
        name.contains("laptop") ||
        name.contains("charger")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("E-Waste Detected ⚠"),
          content: Text(
              "Dispose in designated e-waste bins ♻"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    if (name.contains("paper") ||
        name.contains("food") ||
        name.contains("organic") ||
        name.contains("fruit") ||
        name.contains("vegetable") ||
        name.contains("produce") ||
        name.contains("plant")) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Everyday Waste 🙂"),
          content: Text(
              "Try recycling something impactful 🌱"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Detected: $name"),
        content: Text("Choose action"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final error = await validateTask(name);
              if (error != null) {
                showError(error);
                return;
              }

              saveTask(name);
              openYouTube(name);
            },
            child: Text("Reuse"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final error = await validateTask(name);
              if (error != null) {
                showError(error);
                return;
              }

              await recordRecycleVideo(name);
            },
            child: Text("Recycle"),
          ),
        ],
      ),
    );
  }

  Future<void> recordRecycleVideo(String label) async {
    final pickedFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(seconds: 20),
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    showLoading();

    try {
      final videoUrl = await uploadVideo(file);

      if (_image == null) {
        hideLoading();
        showError("Image missing. Please scan again.");
        return;
      }

      final imageUrl = await uploadImage(_image!);
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user!.uid,
        'beforeImage': imageUrl,
        'videoUrl': videoUrl,
        'type': 'recycle',
        'status': 'awaiting',
        'label': label,
        'createdAt': FieldValue.serverTimestamp(),
      });

      hideLoading();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Video sent for approval 🎥")),
      );
    } catch (e) {
      hideLoading();
      showError("Upload failed: $e");
    }
  }

  Future<String> uploadVideo(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('task_videos/${DateTime.now().millisecondsSinceEpoch}.mp4');

    final uploadTask = await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  Future<String> uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('task_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await ref.putFile(image);

    return await ref.getDownloadURL();
  }

  void saveTask(String label) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _image == null) return;

    showLoading();

    try {
      final url = await uploadImage(_image!);

      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'beforeImage': url,
        'afterImage': null,
        'type': 'reuse',
        'status': 'pending',
        'label': label,
        'createdAt': FieldValue.serverTimestamp(),
      });

      hideLoading();
    } catch (e) {
      hideLoading();
      showError("Upload failed: $e");
    }
  }

  void openYouTube(String label) async {
    final url = Uri.parse(
        "https://www.youtube.com/results?search_query=${Uri.encodeComponent("how to reuse $label")}");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // =========================
  // 🎨 UI (UPGRADED)
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              SizedBox(height: 20),

              Text(
                "Scan Item",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 30),

              // 🔥 IMAGE PREVIEW CARD
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No image selected",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),

              SizedBox(height: 30),

              // 🔥 BUTTONS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text("Use Camera"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: Icon(Icons.upload),
                  label: Text("Upload Image"),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}