import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyRewardsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Rewards",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redemptions')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final rewards = snapshot.data!.docs;

          if (rewards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard,
                      size: 70, color: Colors.grey[300]),
                  SizedBox(height: 10),
                  Text("No rewards redeemed yet"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rewards.length,
            itemBuilder: (context, index) {
              final data =
                  rewards[index].data() as Map<String, dynamic>;

              final createdAt = data['createdAt']?.toDate();

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Code: ${data['code']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text("Points used: ${data['points']}"),
                    if (createdAt != null)
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(createdAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}