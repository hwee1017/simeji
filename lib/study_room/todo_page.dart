import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/hive_service.dart';
import '../models/todo_model.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  late DateTime _selectedDate;
  late DateTime _startOfWeek;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _startOfWeek =
        _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
  }

  String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd', 'ko_KR').format(date);

  List<Todo> get _tasksForSelectedDate {
  final dateKey = _dateKey(_selectedDate);
  return HiveService.getAllTodos()
      .where((todo) => todo.date == dateKey)
      .toList()
    ..sort((a, b) => a.priority.compareTo(b.priority));
  }

  void _addTask() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  final dateKey = _dateKey(_selectedDate);
  final newPriority = HiveService.getTodosByDate(dateKey).length + 1;

  final newTodo = Todo(
    date: dateKey,
    title: text,
    priority: newPriority,
  );

  await HiveService.addTodo(newTodo);
  _controller.clear();
  setState(() {});
}


  void _toggleTask(Todo todo) async {
    todo.isDone = !todo.isDone;
    await HiveService.updateTodo(todo);
    setState(() {});
  }

  void _deleteTask(Todo todo) async {
    await HiveService.deleteTodo(todo.id);
    setState(() {});
  }

  List<DateTime> get _currentWeekDates {
    return List.generate(7, (i) => _startOfWeek.add(Duration(days: i)));
  }

  void _changeWeek(int offset) {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7 * offset));
      _selectedDate = _startOfWeek;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasksForSelectedDate;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ 주간 날짜 선택 바
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _changeWeek(-1),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _currentWeekDates.map((date) {
                      final isSelected =
                          DateUtils.isSameDay(date, _selectedDate);
                      final isToday =
                          DateUtils.isSameDay(date, DateTime.now());
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          width: 35, // 날짜 간격 줄이기
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('E', 'ko_KR').format(date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.blue
                                      : isToday
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? Colors.green
                                            : Colors.black,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ✅ 입력창
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: '할 일을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addTask,
                child: const Text('추가'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 투두 리스트들
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('할 일이 없습니다 😌'))
                : ReorderableListView.builder(
                    itemCount: tasks.length,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final moved = tasks.removeAt(oldIndex);
                      tasks.insert(newIndex, moved);
                      for (int i = 0; i < tasks.length; i++) {
                        tasks[i].priority = i + 1;
                        await HiveService.updateTodo(tasks[i]);
                      }
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTask(task),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isDone,
                              onChanged: (_) => _toggleTask(task),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                decoration:
                                    task.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: const Icon(Icons.drag_handle),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
