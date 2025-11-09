import 'package:flutter/material.dart';
import 'todo_page.dart';
import 'weekly_todo_page.dart';

class RoutineTodoTabs extends StatelessWidget {
  const RoutineTodoTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('To Do List'),
            bottom: const TabBar(
              tabs: [
                Tab(text: '오늘 할일'),
                Tab(text: '이번주 할일'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              TodoPage(),
              WeeklyTodoPage(),
            ],
          ),
        ),
      ),
    );
  }
}
