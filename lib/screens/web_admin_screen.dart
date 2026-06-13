import 'package:flutter/material.dart';
import 'task_admin_screen.dart';
import 'campaign_admin_screen.dart';
import 'reward_admin_screen.dart';

class WebAdminScreen extends StatefulWidget {
  @override
  _WebAdminScreenState createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  String selected = "none";

  Widget getScreen() {
    switch (selected) {
      case "tasks":
        return TaskAdminScreen();
      case "campaigns":
        return CampaignAdminScreen();
      case "rewards":
        return RewardAdminScreen();
      default:
        return Center(child: Text("Select a section"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Web Admin Panel")),
      body: Row(
        children: [

          // 🔹 SIDEBAR
          Container(
            width: 250,
            color: Colors.grey[200],
            child: Column(
              children: [

                sidebarItem("Task Approval", "tasks"),
                sidebarItem("Campaigns", "campaigns"),
                sidebarItem("Rewards", "rewards"),

              ],
            ),
          ),

          // 🔹 MAIN CONTENT
          Expanded(
            child: getScreen(),
          ),
        ],
      ),
    );
  }

  Widget sidebarItem(String title, String value) {
    return ListTile(
      title: Text(title),
      selected: selected == value,
      onTap: () {
        setState(() {
          selected = value;
        });
      },
    );
  }
}