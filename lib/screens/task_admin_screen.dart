import 'package:flutter/material.dart';
import 'task_list_screen.dart';

class TaskAdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Approval",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _adminTile(
              context,
              title: "Reuse Tasks",
              icon: Icons.recycling,
              color: Colors.green,
              type: 'reuse',
            ),

            SizedBox(height: 16),

            _adminTile(
              context,
              title: "Recycle Tasks",
              icon: Icons.delete,
              color: Colors.red,
              type: 'recycle',
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminTile(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required String type}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskListScreen(type: type),
          ),
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
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}