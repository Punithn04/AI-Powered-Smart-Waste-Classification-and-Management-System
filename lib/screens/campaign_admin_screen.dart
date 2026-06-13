import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignAdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Campaigns",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .snapshots(),
        builder: (context, campaignSnapshot) {
          if (campaignSnapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (campaignSnapshot.hasError) {
            return Center(child: Text("Error loading campaigns"));
          }

          final campaigns = campaignSnapshot.data?.docs ?? [];

          return FutureBuilder<List<Widget>>(
            future: _buildCampaignList(context, campaigns),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final widgets = snapshot.data!;

              if (widgets.isEmpty) {
                return Center(
                  child: Text(
                    "No participants for now",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.all(16),
                children: widgets,
              );
            },
          );
        },
      ),
    );
  }

  // =========================
  // 🔥 BUILD LIST (UNCHANGED LOGIC)
  // =========================
  Future<List<Widget>> _buildCampaignList(
      BuildContext context, List<QueryDocumentSnapshot> campaigns) async {
    List<Widget> list = [];

    for (var campaignDoc in campaigns) {
      final campaignData =
          campaignDoc.data() as Map<String, dynamic>;

      final participantSnapshot = await FirebaseFirestore.instance
          .collection('campaign_participants')
          .where('campaignId', isEqualTo: campaignDoc.id)
          .where('status', isEqualTo: 'joined')
          .get();

      final participants = participantSnapshot.docs;

      if (participants.isEmpty) continue;

      list.add(
        Container(
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
          child: ExpansionTile(
            tilePadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              campaignData['title'] ?? "Campaign",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: participants.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text("Loading..."));
                  }

                  final userData =
                      userSnapshot.data!.data()
                          as Map<String, dynamic>?;

                  final name = userData?['name'] ??
                      userData?['email'] ??
                      "User";

                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // ✅ ATTENDED
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12),
                              ),
                              onPressed: () {
                                markAttended(
                                    context,
                                    doc.id,
                                    data,
                                    campaignData);
                              },
                              child: Text("Attended"),
                            ),

                            SizedBox(width: 8),

                            // ❌ MISSED
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.red),
                              onPressed: () {
                                markAbsent(context, doc.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      );
    }

    return list;
  }

  // =========================
  // ✅ ORIGINAL LOGIC (UNCHANGED)
  // =========================

  void markAttended(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    Map<String, dynamic> campaignData,
  ) async {
    final userId = data['userId'];
    final points = campaignData['points'] ?? 0;
    final title = campaignData['title'] ?? "campaign";

    await FirebaseFirestore.instance
        .collection('campaign_participants')
        .doc(docId)
        .update({'status': 'attended'});

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
      'points': points,
      'message':
          "You attended $title and earned $points points 🎉",
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Marked as attended")),
    );
  }

  void markAbsent(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection('campaign_participants')
        .doc(docId)
        .update({'status': 'missed'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Marked as missed")),
    );
  }
}