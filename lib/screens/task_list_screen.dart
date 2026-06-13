import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskListScreen extends StatelessWidget {
  final String type;

  TaskListScreen({required this.type});

  @override
  Widget build(BuildContext context) {
    Query streamQuery = FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'awaiting')
        .where('type', isEqualTo: type);

    if (type == 'reuse') {
      streamQuery =
          streamQuery.where('afterImage', isNotEqualTo: null);
    }

    if (type == 'recycle') {
      streamQuery =
          streamQuery.where('videoUrl', isNotEqualTo: null);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$type Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: streamQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data?.docs ?? [];

          if (tasks.isEmpty) {
            return Center(child: Text("No $type tasks"));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // =========================
                    // 🔄 REUSE UI
                    // =========================
                    if (type == 'reuse') ...[
                      if (data['beforeImage'] != null &&
                          data['beforeImage'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            data['beforeImage'],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(
                              height: 160,
                              child: Center(
                                  child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 160,
                          child: Center(child: Text("No Image")),
                        ),

                      if (data['afterImage'] != null &&
                          data['afterImage'].toString().isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(data['afterImage']),
                          ),
                        ),
                    ],

                    // =========================
                    // ♻ RECYCLE UI
                    // =========================
                    if (type == 'recycle')
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            if (data['beforeImage'] != null &&
                                data['beforeImage']
                                    .toString()
                                    .isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Image.network(
                                  data['beforeImage'],
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 160,
                                child: Center(
                                    child: Text("No Image")),
                              ),

                            SizedBox(height: 10),

                            if (data['videoUrl'] != null &&
                                data['videoUrl']
                                    .toString()
                                    .isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    launchUrl(Uri.parse(
                                        data['videoUrl']));
                                  },
                                  icon: Icon(Icons.play_arrow),
                                  label: Text("Play Video"),
                                ),
                              ),
                          ],
                        ),
                      ),

                    // =========================
                    // 🔹 INFO + ACTIONS
                    // =========================
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Item: ${data['label'] ?? "Unknown"}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    approveDialog(context,
                                        doc.id, data['userId']);
                                  },
                                  child: Text("Approve"),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    rejectDialog(context, doc.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: Text("Reject"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =========================
  // ✅ ORIGINAL LOGIC (UNCHANGED)
  // =========================

  void approveDialog(BuildContext context, String id, String userId) {
    final pointsController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Approve Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Points (max 100)",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 10),

            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: "Compliment",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final input = pointsController.text.trim();

              if (input.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Enter points")),
                );
                return;
              }

              final points = int.tryParse(input);
              if (points == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Only numbers allowed")),
                );
                return;
              }

              if (points > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Max 100 points allowed")),
                );
                return;
              }

              Navigator.pop(context);

              final message = messageController.text.trim();

              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(id)
                  .update({
                'status': 'approved',
                'points': points,
                'message': message,
              });

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .set({
                'points': FieldValue.increment(points),
              }, SetOptions(merge: true));

              await FirebaseFirestore.instance
                  .collection('notifications')
                  .add({
                'userId': userId,
                'title': "You earned $points points 🎉",
                'message': message,
                'createdAt': FieldValue.serverTimestamp(),
              });
            },
            child: Text("Confirm"),
          )
        ],
      ),
    );
  }

  void rejectDialog(BuildContext context, String id) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Reject Task"),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: "Reason"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(id)
                  .update({
                'status': 'rejected',
                'reason': reasonController.text,
              });
            },
            child: Text("Confirm"),
          )
        ],
      ),
    );
  }
}