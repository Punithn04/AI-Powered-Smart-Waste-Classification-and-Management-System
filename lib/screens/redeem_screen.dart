import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RedeemScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Redeem Rewards",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rewards')
            .snapshots(),
        builder: (context, rewardSnapshot) {

          if (!rewardSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final rewards = rewardSnapshot.data!.docs;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, userSnapshot) {

              if (!userSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;

              final userPoints = userData?['points'] ?? 0;

              return Column(
                children: [

                  // 🔥 POINTS CARD
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6C63FF),
                          Color(0xFF8E7CFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Your Points: $userPoints",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final reward =
                            rewards[index].data() as Map<String, dynamic>;

                        final cost = reward['points'] ?? 0;

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
                                reward['title'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text("Cost: $cost points"),
                              SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: userPoints >= cost
                                      ? () {
                                          redeemReward(
                                              context, rewards[index].id, cost);
                                        }
                                      : null,
                                  child: Text("Redeem"),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void redeemReward(BuildContext context, String rewardId, int cost) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('reward_codes')
          .where('rewardId', isEqualTo: rewardId)
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No codes available")),
        );
        return;
      }

      final codeDoc = query.docs.first;
      final code = codeDoc['code'];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'points': FieldValue.increment(-cost)});

      await FirebaseFirestore.instance
          .collection('reward_codes')
          .doc(codeDoc.id)
          .update({'isUsed': true});

      await FirebaseFirestore.instance
          .collection('redemptions')
          .add({
        'userId': user.uid,
        'rewardId': rewardId,
        'code': code,
        'points': cost,
        'createdAt': FieldValue.serverTimestamp(),
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("🎉 Reward Redeemed"),
          content: SelectableText(code,
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}