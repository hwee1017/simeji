import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공대학술제!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// -------------------- 메인 화면 (탭 구조) --------------------
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CharacterPage(),
    const CalendarPage(),
    const SettingsPage(),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '메인'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '캘린더'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}

// -------------------- ① 메인 탭 --------------------
class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});
  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  int headIndex = 0;
  int faceIndex = 0;
  int outfitIndex = 0;

  final List<String> heads = ['👒', '🎩', '🧢'];
  final List<String> faces = ['😀', '😎', '🥸'];
  final List<String> outfits = ['👕', '🧥', '👔'];

  void _nextItem(String part) {
    setState(() {
      if (part == 'head') headIndex = (headIndex + 1) % heads.length;
      if (part == 'face') faceIndex = (faceIndex + 1) % faces.length;
      if (part == 'outfit') outfitIndex = (outfitIndex + 1) % outfits.length;
    });
  }

  void _prevItem(String part) {
    setState(() {
      if (part == 'head') headIndex = (headIndex - 1 + heads.length) % heads.length;
      if (part == 'face') faceIndex = (faceIndex - 1 + faces.length) % faces.length;
      if (part == 'outfit') outfitIndex = (outfitIndex - 1 + outfits.length) % outfits.length;
    });
  }

  void _saveCharacter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('캐릭터가 저장되었습니다!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('내 캐릭터', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('${heads[headIndex]} ${faces[faceIndex]} ${outfits[outfitIndex]}',
                style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 20),

            // 머리 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _prevItem('head'), icon: const Icon(Icons.arrow_left)),
                const Text('머리'),
                IconButton(onPressed: () => _nextItem('head'), icon: const Icon(Icons.arrow_right)),
              ],
            ),

            // 얼굴 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _prevItem('face'), icon: const Icon(Icons.arrow_left)),
                const Text('얼굴'),
                IconButton(onPressed: () => _nextItem('face'), icon: const Icon(Icons.arrow_right)),
              ],
            ),

            // 옷 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => _prevItem('outfit'), icon: const Icon(Icons.arrow_left)),
                const Text('옷'),
                IconButton(onPressed: () => _nextItem('outfit'), icon: const Icon(Icons.arrow_right)),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCharacter,
              child: const Text('저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ② 캘린더 탭 --------------------
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final List<String> _todos = [];
  final TextEditingController _controller = TextEditingController();

  void _addTodo() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _todos.add(_controller.text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('오늘의 할 일', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: '할 일 입력'))),
                  IconButton(onPressed: _addTodo, icon: const Icon(Icons.add_circle)),
                ],
              ),
            ),
            for (var todo in _todos)
              ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: Text(todo),
              ),
            const Divider(),
            const Text('📅 (여기에 실제 캘린더 위젯 추가 가능)', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// -------------------- ③ 설정 탭 --------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.login),
            title: Text('로그인'),
            subtitle: Text('계정 로그인 또는 변경'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('알림 설정'),
            subtitle: Text('푸시 알림 허용 여부 변경'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('앱 정보'),
            subtitle: Text('버전 1.0.0'),
          ),
          SizedBox(height: 200),
        ],
      ),
    );
  }
}