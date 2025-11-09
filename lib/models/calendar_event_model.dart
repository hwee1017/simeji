import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'calendar_event_model.g.dart';

@HiveType(typeId: 3)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime start;

  @HiveField(4)
  late DateTime end;

  @HiveField(5)
  late String location;

  @HiveField(6)
  late bool isAllDay;

  @HiveField(7)
  bool needsSync = false;

  CalendarEvent({
    String? id,
    required this.title,
    this.description = "",
    required this.start,
    required this.end,
    this.location = "",
    this.isAllDay = false,
    this.needsSync = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'location': location,
      'isAllDay': isAllDay,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? "",
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      location: json['location'] ?? "",
      isAllDay: json['isAllDay'] ?? false,
      needsSync: false,
    );
  }
}