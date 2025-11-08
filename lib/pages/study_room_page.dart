import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'stopwatch_page.dart';
import 'timetable_page.dart';
import 'todo_tabs.dart';

class StudyRoomPage extends StatefulWidget {
  const StudyRoomPage({super.key});

  @override
  State<StudyRoomPage> createState() => _StudyRoomPageState();
}

class _StudyRoomPageState extends State<StudyRoomPage> {
  int _selectedIndex = 0;

  // 각 탭의 페이지들
  final List<Widget> _pages = const [
    StudyHomePage(),
    TimetablePage(),
    StopwatchPage(),
    CalendarPage(),
    RoutineTodoTabs(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '독서실',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: '시간표',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: '스톱워치',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),          
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'To-Do',
          ),
        ],
      ),
    );
  }
}

/// 독서실 홈 화면
class StudyHomePage extends StatelessWidget {
  const StudyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('독서실'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '이곳은 정숙한 독서실입니다 🏫',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
