import 'package:flutter/material.dart';
import 'campaign_admin_screen.dart';
import 'add_campaign_screen.dart';

class CampaignMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Campaign Management",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _menuCard(
              context,
              title: "Add Campaign",
              icon: Icons.add,
              color: Colors.green,
              screen: AddCampaignScreen(),
            ),

            SizedBox(height: 16),

            _menuCard(
              context,
              title: "Manage Participants",
              icon: Icons.group,
              color: Colors.deepPurple,
              screen: CampaignAdminScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required Widget screen}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}