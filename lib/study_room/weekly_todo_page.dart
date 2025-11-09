import 'package:flutter/material.dart';
import '../models/weekly_task_model.dart';
import '../services/hive_service.dart';

class WeeklyTodoPage extends StatefulWidget {
  const WeeklyTodoPage({super.key});

  @override
  State<WeeklyTodoPage> createState() => _WeeklyTodoPageState();
}

class _WeeklyTodoPageState extends State<WeeklyTodoPage> {
  final TextEditingController _mainController = TextEditingController();
  final TextEditingController _subController = TextEditingController();

  late int _currentYear;
  late int _currentWeek;
  List<WeeklyTask> _weeklyTasks = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;

    // ✅ 안전한 ISO 주차 계산 (DateFormat('w') 대신)
    final firstThursday = DateTime(now.year, 1, 1)
        .add(Duration(days: (4 - DateTime(now.year, 1, 1).weekday + 7) % 7));
    final week =
        ((now.difference(firstThursday).inDays) / 7).floor() + 1; // ISO 8601 기준
    _currentWeek = week > 0 ? week : 1;

    _loadWeeklyTasks();
  }

  void _loadWeeklyTasks() {
    setState(() {
      _weeklyTasks =
          HiveService.getWeeklyTasksByWeek(_currentYear, _currentWeek);
    });
  }

  Future<void> _addMainTask() async {
    final title = _mainController.text.trim();
    if (title.isEmpty) return;

    final task = WeeklyTask(
      year: _currentYear,
      week: _currentWeek,
      title: title,
    );

    await HiveService.addWeeklyTask(task);
    _mainController.clear();
    _loadWeeklyTasks();
  }

  Future<void> _addSubTask(WeeklyTask task) async {
    final title = _subController.text.trim();
    if (title.isEmpty) return;

    task.subtasks.add(SubTask(name: title));
    await HiveService.updateWeeklyTask(task);
    _subController.clear();
    _loadWeeklyTasks();
  }

  Future<void> _toggleSubTask(WeeklyTask task, int index) async {
    task.subtasks[index].isDone = !task.subtasks[index].isDone;
    await HiveService.updateWeeklyTask(task);
    _loadWeeklyTasks();
  }

  Future<void> _deleteMainTask(WeeklyTask task) async {
    await HiveService.deleteWeeklyTask(task.id);
    _loadWeeklyTasks();
  }

  Future<void> _deleteSubTask(WeeklyTask task, int index) async {
    task.subtasks.removeAt(index);
    await HiveService.updateWeeklyTask(task);
    _loadWeeklyTasks();
  }

  double _progress(WeeklyTask task) {
    final subs = task.subtasks;
    if (subs.isEmpty) return 0.0;
    final doneCount = subs.where((e) => e.isDone).length;
    return doneCount / subs.length;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 큰 과제 입력
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mainController,
                    decoration: const InputDecoration(
                      labelText: '큰 과제 추가',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addMainTask,
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 할일 리스트
            _weeklyTasks.isEmpty
                ? const Center(child: Text('이번주 과제를 추가해보세요 ✏️'))
                : Column(
                    children: _weeklyTasks.map((task) {
                      return Dismissible(
                        key: Key(task.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteMainTask(task),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.redAccent,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                          begin: 0.0, end: _progress(task)),
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeInOutCubic,
                                      builder: (context, value, child) {
                                        return LinearProgressIndicator(
                                          value: value,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.blueAccent,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ...task.subtasks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final sub = entry.value;
                                return Dismissible(
                                  key: Key(sub.id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) =>
                                      _deleteSubTask(task, index),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: sub.isDone,
                                      onChanged: (_) =>
                                          _toggleSubTask(task, index),
                                    ),
                                    title: Text(
                                      sub.name,
                                      style: TextStyle(
                                        decoration: sub.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _subController,
                                        decoration: const InputDecoration(
                                          labelText: '세부 과제 추가',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () => _addSubTask(task),
                                      child: const Text('추가'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
