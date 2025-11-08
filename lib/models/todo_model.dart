import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String date;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late int priority;

  @HiveField(4)
  late bool isDone;

  @HiveField(5)
  bool needsSync = false;

  Todo({
    String? id,
    required this.date,
    required this.title,
    required this.priority,
    this.isDone = false,
    this.needsSync = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'priority': priority,
      'isDone': isDone,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      date: json['date'],
      title: json['title'],
      priority: json['priority'],
      isDone: json['isDone'] ?? false,
      needsSync: false,
    );
  }
}