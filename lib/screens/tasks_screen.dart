import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "Reuse"),
            Tab(text: "Recycle"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildTaskList('reuse', user),
          buildTaskList('recycle', user),
        ],
      ),
    );
  }

  Widget buildTaskList(String type, User? user) {
    if (user == null) {
      return Center(child: Text("User not logged in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final allTasks = snapshot.data?.docs ?? [];

        final tasks = allTasks.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return data['userId'] == user.uid;
        }).toList();

        // 🔥 EMPTY STATE UI IMPROVED
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "No $type tasks",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final doc = tasks[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};

            final label = data['label'] ?? "Unknown";
            final status = data['status'] ?? "pending";
            final image = data['beforeImage'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(
                      taskId: doc.id,
                      data: data,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 🔥 IMAGE BOX
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: image != null
                          ? Image.network(
                              image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                    ),

                    SizedBox(width: 14),

                    // 🔥 TEXT AREA
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 6),

                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == "approved"
                                      ? Colors.green.withOpacity(0.1)
                                      : status == "rejected"
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == "approved"
                                        ? Colors.green
                                        : status == "rejected"
                                            ? Colors.red
                                            : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}