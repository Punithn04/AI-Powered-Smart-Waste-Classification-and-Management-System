class Task {
  String id;
  String beforeImage;
  String? afterImage;
  String status;
  String label;

  Task({
    required this.id,
    required this.beforeImage,
    this.afterImage,
    required this.status,
    required this.label,
  });

  // 🔥 Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beforeImage': beforeImage,
      'afterImage': afterImage,
      'status': status,
      'label': label,
    };
  }

  // 🔥 Convert from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      beforeImage: json['beforeImage'],
      afterImage: json['afterImage'],
      status: json['status'],
      label: json['label'],
    );
  }
}