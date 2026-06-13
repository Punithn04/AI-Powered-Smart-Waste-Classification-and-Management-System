import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recycle_app/screens/admin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'leaderboard_screen.dart';
import 'redeem_screen.dart';
import 'my_rewards_screen.dart';
import 'campaign_screen.dart';

Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data()?['role'] == 'admin';
}

class ProfileScreen extends StatelessWidget {
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔥 HEADER
              Text(
                "Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              // 🔥 USER CARD
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 30),
                      ),
                      SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? "No user",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),

                            // 🔥 POINTS (UNCHANGED LOGIC)
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user?.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Text("Loading...");
                                }

                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>?;

                                return Text(
                                  "Points: ${data?['points'] ?? 0}",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 🔐 ADMIN PANEL
              FutureBuilder<bool>(
                future: isAdmin(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return SizedBox();

                  if (snapshot.data == true) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _menuItem(
                        icon: Icons.admin_panel_settings,
                        title: "Admin Panel",
                        color: Colors.deepPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => AdminScreen()),
                          );
                        },
                      ),
                    );
                  } else {
                    return SizedBox();
                  }
                },
              ),

              // 🔥 MENU LIST
              _menuItem(
                icon: Icons.campaign,
                title: "Campaigns",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CampaignScreen()),
                  );
                },
              ),

              _menuItem(
                icon: Icons.notifications,
                title: "Notifications",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NotificationScreen()),
                  );
                },
              ),

              _menuItem(
                icon: Icons.card_giftcard,
                title: "Redeem Rewards",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RedeemScreen()),
                  );
                },
              ),

              _menuItem(
                icon: Icons.wallet,
                title: "My Rewards",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MyRewardsScreen()),
                  );
                },
              ),

              _menuItem(
                icon: Icons.leaderboard,
                title: "Leaderboard",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LeaderboardScreen()),
                  );
                },
              ),

              Spacer(),

              // 🔥 LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Logout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 REUSABLE MENU ITEM
  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.black),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}