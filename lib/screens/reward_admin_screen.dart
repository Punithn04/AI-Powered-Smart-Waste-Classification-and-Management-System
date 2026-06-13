import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class RewardAdminScreen extends StatelessWidget {
  final titleController = TextEditingController();
  final pointsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Gift Cards",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            adminCard(
              context,
              "Add Gift Card",
              Icons.add,
              Colors.green,
              () => showAddRewardDialog(context),
            ),
            adminCard(
              context,
              "Manage Gift Cards",
              Icons.settings,
              Colors.deepPurple,
              () => showManageRewards(context),
            ),
            adminCard(
              context,
              "Add Codes",
              Icons.code,
              Colors.orange,
              () => showSelectRewardForCodes(context),
            ),
            adminCard(
              context,
              "Edit Gift Card",
              Icons.edit,
              Colors.blue,
              () => showEditRewards(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminCard(BuildContext context, String title, IconData icon,
      Color color, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 🟢 ADD REWARD (UNCHANGED LOGIC)
  // =========================
  void showAddRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Gift Card"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Points",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final points = int.tryParse(pointsController.text) ?? 0;

              if (title.isEmpty || points == 0) return;

              await FirebaseFirestore.instance.collection('rewards').add({
                'title': title,
                'points': points,
                'isActive': true,
              });

              titleController.clear();
              pointsController.clear();

              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  // =========================
  // 🔵 MANAGE REWARD
  // =========================
  void showManageRewards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("Manage Rewards")),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('rewards').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final rewards = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final doc = rewards[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('reward_codes')
                        .where('rewardId', isEqualTo: doc.id)
                        .where('isUsed', isEqualTo: false)
                        .get(),
                    builder: (context, codeSnap) {
                      if (!codeSnap.hasData)
                        return ListTile(title: Text("Loading..."));

                      final count = codeSnap.data!.docs.length;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: (data['isActive'] ?? true)
                              ? Colors.white
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Opacity(
                          opacity: (data['isActive'] ?? true) ? 1 : 0.6,
                          child: ListTile(
                            title: Text(data['title']),
                            subtitle: count == 0
                                ? Text("No codes available",
                                    style: TextStyle(color: Colors.red))
                                : Text("Codes left: $count"),
                            trailing: Switch(
                              value: data['isActive'] ?? true,
                              onChanged: (val) {
                                FirebaseFirestore.instance
                                    .collection('rewards')
                                    .doc(doc.id)
                                    .update({'isActive': val});
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================
  // 🟣 SELECT REWARD
  // =========================
  void showSelectRewardForCodes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("Select Reward")),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('rewards').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final rewards = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final doc = rewards[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(
                        data['title'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Tap to add codes"),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () => showCodeOptions(context, doc.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================
  // 🟣 OPTIONS
  // =========================
  void showCodeOptions(BuildContext context, String rewardId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Codes"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              addSingleCode(context, rewardId);
            },
            child: Text("Single Code"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              uploadBulkCodes(context, rewardId);
            },
            child: Text("Bulk Upload"),
          ),
        ],
      ),
    );
  }

  // =========================
  // ➕ SINGLE CODE (UNCHANGED)
  // =========================
  void addSingleCode(BuildContext context, String rewardId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Code"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "Enter Code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final code = controller.text.trim();

              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Enter valid code")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('reward_codes')
                  .add({
                'rewardId': rewardId,
                'code': code,
                'isUsed': false,
              });

              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  // =========================
  // 📥 BULK UPLOAD (UNCHANGED)
  // =========================
  void uploadBulkCodes(BuildContext context, String rewardId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;

      if (file.bytes == null) {
        throw Exception("File read failed");
      }

      final content = String.fromCharCodes(file.bytes!);
      final rawCodes = content.split('\n');

      final fileCodes = rawCodes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();

      int total = fileCodes.length;
      int uploaded = 0;
      int duplicates = 0;

      ValueNotifier<double> progress = ValueNotifier(0);

      final existingSnapshot = await FirebaseFirestore.instance
          .collection('reward_codes')
          .where('rewardId', isEqualTo: rewardId)
          .get();

      final existingCodes = existingSnapshot.docs
          .map((doc) => doc['code'].toString())
          .toSet();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text("Uploading Codes"),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: value),
                  SizedBox(height: 10),
                  Text("$uploaded / $total processed"),
                ],
              );
            },
          ),
        ),
      );

      await Future.delayed(Duration(milliseconds: 300));

      for (var code in fileCodes) {
        if (existingCodes.contains(code)) {
          duplicates++;
        } else {
          await FirebaseFirestore.instance
              .collection('reward_codes')
              .add({
            'rewardId': rewardId,
            'code': code,
            'isUsed': false,
          });

          uploaded++;
        }

        progress.value = (uploaded + duplicates) / total;

        await Future.delayed(Duration(milliseconds: 30));
      }

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Upload Summary"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("✅ $uploaded codes added"),
              SizedBox(height: 8),
              Text("⚠ $duplicates duplicates skipped"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    }
  }

  // =========================
  // 🟠 EDIT REWARDS (UNCHANGED)
  // =========================
  void showEditRewards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("Edit Rewards")),
          body: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('rewards').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final rewards = snapshot.data!.docs;

              return ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final doc = rewards[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      title: Text(
                        data['title'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Points: ${data['points']}"),
                      trailing: Icon(Icons.edit),
                      onTap: () =>
                          editRewardDialog(context, doc.id, data),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void editRewardDialog(BuildContext context, String id, Map data) {
    final title = TextEditingController(text: data['title']);
    final points =
        TextEditingController(text: data['points'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit Reward"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: InputDecoration(
                  border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: points,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('rewards')
                  .doc(id)
                  .update({
                'title': title.text,
                'points': int.parse(points.text),
              });

              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }
}