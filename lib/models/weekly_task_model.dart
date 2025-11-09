import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'weekly_task_model.g.dart';

@HiveType(typeId: 1)
class WeeklyTask extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int year;

  @HiveField(2)
  late int week;

  @HiveField(3)
  late String title;

  @HiveField(4)
  late List<SubTask> subtasks;

  @HiveField(5)
  bool needsSync = false;

  WeeklyTask({
    String? id,
    required this.year,
    required this.week,
    required this.title,
    List<SubTask>? subtasks,
    this.needsSync = true,
  })  : id = id ?? const Uuid().v4(),
        subtasks = subtasks ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'week': week,
      'title': title,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
    };
  }

  factory WeeklyTask.fromJson(Map<String, dynamic> json) {
    return WeeklyTask(
      id: json['id'],
      year: json['year'],
      week: json['week'],
      title: json['title'],
      subtasks: (json['subtasks'] as List?)
              ?.map((e) => SubTask.fromJson(e))
              .toList() ??
          [],
      needsSync: false,
    );
  }
}

@HiveType(typeId: 2)
class SubTask {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late bool isDone;

  SubTask({
    String? id,
    required this.name,
    this.isDone = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isDone': isDone,
    };
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'],
      name: json['name'],
      isDone: json['isDone'] ?? false,
    );
  }
}