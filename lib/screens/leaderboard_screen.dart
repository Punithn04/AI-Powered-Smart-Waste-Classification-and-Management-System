import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return Center(child: Text("Error loading leaderboard"));
          }

          final users = snapshot.data?.docs ?? [];

          // 📭 Empty
          if (users.isEmpty) {
            return Center(child: Text("No users yet"));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              final isCurrentUser = doc.id == currentUser?.uid;

              // 🥇🥈🥉 Top 3 Colors
              Color bgColor = Colors.white;
              if (index == 0) bgColor = Colors.amber.shade100;
              if (index == 1) bgColor = Colors.grey.shade200;
              if (index == 2) bgColor = Colors.brown.shade100;

              if (isCurrentUser) {
                bgColor = Colors.blue.shade100;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    // 🏆 Rank Circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 14),

                    // 👤 USER INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? data['email'] ?? "User",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isCurrentUser
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Points: ${data['points'] ?? 0}",
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ⭐ Highlight current user
                    if (isCurrentUser)
                      Icon(Icons.star, color: Colors.orange),
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