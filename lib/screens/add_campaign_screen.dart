import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AddCampaignScreen extends StatefulWidget {
  @override
  _AddCampaignScreenState createState() => _AddCampaignScreenState();
}

class _AddCampaignScreenState extends State<AddCampaignScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final pointsController = TextEditingController();
  final cityController = TextEditingController();
  final expectedController = TextEditingController();

  String? mapLink;
  DateTime? selectedDate;

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void openMap() async {
    final url = Uri.parse("https://www.google.com/maps");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void addCampaign() async {
    if (titleController.text.isEmpty ||
        pointsController.text.isEmpty ||
        selectedDate == null) return;

    await FirebaseFirestore.instance.collection('campaigns').add({
      'title': titleController.text,
      'description': descController.text,
      'points': int.parse(pointsController.text),
      'city': cityController.text,
      'mapLink': mapLink ?? "",
      'expectedCount': int.tryParse(expectedController.text) ?? 0,
      'joinedCount': 0,
      'date': selectedDate,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Widget buildField(
      {required TextEditingController? controller,
      required String label,
      TextInputType? type,
      Function(String)? onChanged}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Campaign",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            buildField(
                controller: titleController, label: "Title"),

            buildField(
                controller: descController, label: "Description"),

            buildField(
              controller: pointsController,
              label: "Points",
              type: TextInputType.number,
            ),

            buildField(
                controller: cityController, label: "City"),

            SizedBox(height: 10),

            // 📍 MAP BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: openMap,
                icon: Icon(Icons.map),
                label: Text("Pick Location (Google Maps)"),
              ),
            ),

            SizedBox(height: 12),

            buildField(
              controller: null,
              label: "Paste Map Link",
              onChanged: (val) => mapLink = val,
            ),

            buildField(
              controller: expectedController,
              label: "Required Members",
              type: TextInputType.number,
            ),

            SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: pickDateTime,
                child: Text(
                  selectedDate == null
                      ? "Select Date & Time"
                      : selectedDate.toString(),
                ),
              ),
            ),

            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addCampaign,
                child: Text("Create Campaign"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}