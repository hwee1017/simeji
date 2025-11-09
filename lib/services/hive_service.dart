import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_model.dart';
import '../models/weekly_task_model.dart';
import '../models/calendar_event_model.dart';

class HiveService {
  static const String todoBoxName = 'todos';
  static const String weeklyTaskBoxName = 'weeklyTasks';
  static const String calendarEventBoxName = 'calendarEvents';

  static late Box<Todo> todoBox;
  static late Box<WeeklyTask> weeklyTaskBox;
  static late Box<CalendarEvent> calendarEventBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // await Hive.deleteBoxFromDisk('todos');
    // await Hive.deleteBoxFromDisk('weeklyTasks');
    // await Hive.deleteBoxFromDisk('calendarEvents');

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TodoAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WeeklyTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SubTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(CalendarEventAdapter());
    }

    // Open boxes
    todoBox = await Hive.openBox<Todo>(todoBoxName);
    weeklyTaskBox = await Hive.openBox<WeeklyTask>(weeklyTaskBoxName);
    calendarEventBox = await Hive.openBox<CalendarEvent>(calendarEventBoxName);
  }

  // Todo CRUD operations
  static Future<void> addTodo(Todo todo) async {
    await todoBox.put(todo.id, todo);
  }

  static Todo? getTodo(String id) {
    return todoBox.get(id);
  }

  static List<Todo> getAllTodos() {
    return todoBox.values.toList();
  }

  static List<Todo> getTodosByDate(String date) {
    return todoBox.values.where((todo) => todo.date == date).toList();
  }

  static Future<void> updateTodo(Todo todo) async {
    todo.needsSync = true;
    await todo.save();
  }

  static Future<void> deleteTodo(String id) async {
    await todoBox.delete(id);
  }

  // WeeklyTask CRUD operations
  static Future<void> addWeeklyTask(WeeklyTask task) async {
    await weeklyTaskBox.put(task.id, task);
  }

  static WeeklyTask? getWeeklyTask(String id) {
    return weeklyTaskBox.get(id);
  }

  static List<WeeklyTask> getAllWeeklyTasks() {
    return weeklyTaskBox.values.toList();
  }

  static List<WeeklyTask> getWeeklyTasksByWeek(int year, int week) {
    return weeklyTaskBox.values
        .where((task) => task.year == year && task.week == week)
        .toList();
  }

  static Future<void> updateWeeklyTask(WeeklyTask task) async {
    task.needsSync = true;
    await task.save();
  }

  static Future<void> deleteWeeklyTask(String id) async {
    await weeklyTaskBox.delete(id);
  }

  // CalendarEvent CRUD operations
  static Future<void> addCalendarEvent(CalendarEvent event) async {
    await calendarEventBox.put(event.id, event);
  }

  static CalendarEvent? getCalendarEvent(String id) {
    return calendarEventBox.get(id);
  }

  static List<CalendarEvent> getAllCalendarEvents() {
    return calendarEventBox.values.toList();
  }

  static List<CalendarEvent> getCalendarEventsByDateRange(
      DateTime start, DateTime end) {
    return calendarEventBox.values
        .where((event) =>
            event.start.isAfter(start.subtract(const Duration(days: 1))) &&
            event.start.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  static Future<void> updateCalendarEvent(CalendarEvent event) async {
    event.needsSync = true;
    await event.save();
  }

  static Future<void> deleteCalendarEvent(String id) async {
    await calendarEventBox.delete(id);
  }

  // Get items that need sync
  static List<Todo> getTodosNeedingSync() {
    return todoBox.values.where((todo) => todo.needsSync).toList();
  }

  static List<WeeklyTask> getWeeklyTasksNeedingSync() {
    return weeklyTaskBox.values.where((task) => task.needsSync).toList();
  }

  static List<CalendarEvent> getCalendarEventsNeedingSync() {
    return calendarEventBox.values.where((event) => event.needsSync).toList();
  }

  // Clear all data
  static Future<void> clearAll() async {
    await todoBox.clear();
    await weeklyTaskBox.clear();
    await calendarEventBox.clear();
  }
}