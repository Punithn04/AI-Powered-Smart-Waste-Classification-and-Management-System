import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

List<Task> taskList = [];

Future<void> saveTasks() async {
  final prefs = await SharedPreferences.getInstance();

  List<String> taskJsonList =
      taskList.map((task) => jsonEncode(task.toJson())).toList();

  await prefs.setStringList('tasks', taskJsonList);
}

Future<void> loadTasks() async {
  final prefs = await SharedPreferences.getInstance();

  final List<String>? taskJsonList = prefs.getStringList('tasks');

  if (taskJsonList != null) {
    taskList = taskJsonList
        .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
        .toList();
  }
}