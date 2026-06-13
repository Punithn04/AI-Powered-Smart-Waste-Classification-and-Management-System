import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CampaignScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Campaigns",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .snapshots(),
        builder: (context, campaignSnapshot) {
          if (!campaignSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final campaigns = campaignSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('campaign_participants')
                .where('userId', isEqualTo: user?.uid)
                .snapshots(),
            builder: (context, participantSnapshot) {
              if (!participantSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final participants = participantSnapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: campaigns.length,
                itemBuilder: (context, index) {
                  final doc = campaigns[index];
                  final data = doc.data() as Map<String, dynamic>;

                  autoMarkMissed(doc);

                  final eventTime = data['date']?.toDate();
                  final now = DateTime.now();

                  bool canJoin = true;

                  if (eventTime != null &&
                      now.isAfter(eventTime.add(Duration(hours: 3)))) {
                    canJoin = false;
                  }

                  final match = participants.where((p) {
                    final pdata = p.data() as Map<String, dynamic>;
                    return pdata['campaignId'] == doc.id;
                  }).toList();

                  final hasJoined = match.isNotEmpty;
                  final status =
                      hasJoined ? match.first['status'] : null;

                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 🔥 TITLE
                        Text(
                          data['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          data['description'] ?? "",
                          style: TextStyle(color: Colors.grey[700]),
                        ),

                        SizedBox(height: 12),

                        // 🎁 POINTS
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.orange, size: 18),
                            SizedBox(width: 6),
                            Text("Points: ${data['points']}"),
                          ],
                        ),

                        SizedBox(height: 6),

                        // 📅 DATE
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16),
                            SizedBox(width: 6),
                            Text(
                              eventTime != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(eventTime)
                                  : "Date not set",
                            ),
                          ],
                        ),

                        SizedBox(height: 6),

                        // 👥 PARTICIPANTS
                        Row(
                          children: [
                            Icon(Icons.people, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "${data['joinedCount'] ?? 0} / ${data['expectedCount'] ?? 0} joined",
                            ),
                          ],
                        ),

                        SizedBox(height: 12),

                        // 📍 LOCATION BUTTON
                        if (data['mapLink'] != null &&
                            data['mapLink'].toString().isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse(data['mapLink']);
                                await launchUrl(url);
                              },
                              icon: Icon(Icons.location_on),
                              label: Text("${data['city']}"),
                            ),
                          ),

                        SizedBox(height: 10),

                        // 🎯 JOIN / STATUS
                        if (!hasJoined)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: canJoin
                                  ? () {
                                      joinCampaign(
                                          context, doc.id, user?.uid ?? "");
                                    }
                                  : null,
                              child: Text(
                                  canJoin ? "Join Campaign" : "Closed"),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: status == "attended"
                                  ? Colors.green
                                  : status == "missed"
                                      ? Colors.red
                                      : Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                status == "attended"
                                    ? "Attended ✅"
                                    : status == "missed"
                                        ? "Missed ❌"
                                        : "Joined (Waiting)",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void joinCampaign(
      BuildContext context, String campaignId, String userId) async {
    await FirebaseFirestore.instance
        .collection('campaign_participants')
        .add({
      'campaignId': campaignId,
      'userId': userId,
      'status': 'joined',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('campaigns')
        .doc(campaignId)
        .update({
      'joinedCount': FieldValue.increment(1),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Joined campaign successfully")),
    );
  }

  void autoMarkMissed(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? ts = data['date'];
    if (ts == null) return;

    final eventDate = ts.toDate();
    final now = DateTime.now();

    if (now.isAfter(eventDate.add(Duration(days: 3)))) {
      final participants = await FirebaseFirestore.instance
          .collection('campaign_participants')
          .where('campaignId', isEqualTo: doc.id)
          .where('status', isEqualTo: 'joined')
          .get();

      for (var p in participants.docs) {
        await p.reference.update({'status': 'missed'});
      }
    }
  }
}