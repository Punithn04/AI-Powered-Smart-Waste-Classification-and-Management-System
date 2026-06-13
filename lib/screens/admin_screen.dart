import 'package:flutter/material.dart';
import 'task_admin_screen.dart';
import 'campaign_menu_screen.dart';
import 'reward_admin_screen.dart';
import 'send_notification_screen.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [

            _adminTile(
              context,
              title: "Task Approval",
              icon: Icons.check_circle,
              color: Colors.green,
              screen: TaskAdminScreen(),
            ),

            _adminTile(
              context,
              title: "Campaigns",
              icon: Icons.campaign,
              color: Colors.deepPurple,
              screen: CampaignMenuScreen(),
            ),

            _adminTile(
              context,
              title: "Gift Cards",
              icon: Icons.card_giftcard,
              color: Colors.orange,
              screen: RewardAdminScreen(),
            ),

            _adminTile(
              context,
              title: "Notifications",
              icon: Icons.notifications,
              color: Colors.blue,
              screen: SendNotificationScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 MODERN DASHBOARD TILE
  Widget _adminTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ICON
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),

            SizedBox(height: 14),

            // TITLE
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}