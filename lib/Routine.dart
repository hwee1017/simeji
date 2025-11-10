import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✅ Hive 추가

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '루틴 관리',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF101010),
      ),
      home: const RoutineScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
    );
  }
}

class Routine {
  final String title;
  final String emoji;
  bool isDone;
  Routine({required this.title, required this.emoji, this.isDone = false});
}

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});
  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  List<Routine> routines = [
    Routine(title: '알람 울리자마자 일어나기', emoji: '👍'),
    Routine(title: '영양제 먹기', emoji: '💊'),
    Routine(title: '전공 공부하기', emoji: '📖'),
    Routine(title: '코딩 공부하기', emoji: '✅'),
    Routine(title: '교양 공부하기', emoji: '📚'),
    Routine(title: '10분 독서하기', emoji: '📗'),
    Routine(title: '운동하기', emoji: '💧'),
  ];

  int coins = 0;
  final DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRoutines(); // ✅ 루틴과 코인 불러오기
  }

  // ✅ Hive에서 코인과 루틴 불러오기
  void _loadRoutines() async {
    final box = Hive.box('coinsBox');

    final savedList = box.get('routines', defaultValue: []);
    final loadedRoutines = (savedList as List)
        .map((e) => Routine(
      title: e['title'],
      emoji: e['emoji'],
      isDone: e['isDone'],
    ))
        .toList();

    setState(() {
      coins = box.get('coins', defaultValue: 0);
      if (loadedRoutines.isNotEmpty) {
        routines = loadedRoutines;
      }
    });

    print("✅ Hive에서 불러온 루틴: ${routines.length}개, 코인: $coins");
  }

  // ✅ Hive에 루틴 + 코인 저장
  Future<void> _saveRoutines() async {
    final box = Hive.box('coinsBox');
    final routineList = routines
        .map((r) => {"title": r.title, "emoji": r.emoji, "isDone": r.isDone})
        .toList();
    await box.put('routines', routineList);
    await box.put('coins', coins);
    print("💾 Hive에 루틴과 코인 저장 완료");
  }

  @override
  void dispose() {
    _saveRoutines(); // ✅ 앱 종료 시 저장
    super.dispose();
  }

  void _toggleRoutine(int index) async {
    setState(() {
      final routine = routines[index];
      routine.isDone = !routine.isDone;

      if (routine.isDone) {
        coins += 5;
        _showCoinPopup(routine.emoji);
      } else {
        coins -= 5;
      }

      _sortRoutines();
    });

    await _saveRoutines(); // ✅ 상태 변경 시 즉시 저장
  }

  void _sortRoutines() {
    routines.sort((a, b) {
      if (a.isDone == b.isDone) return 0;
      return a.isDone ? 1 : -1;
    });
  }

  void _showCoinPopup(String emoji) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$emoji 루틴 완료!",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              "💰 코인 +5 지급!",
              style: TextStyle(color: Colors.greenAccent, fontSize: 18),
            ),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  String _dateString(DateTime date) {
    final day = DateFormat('EEEE', 'ko_KR').format(date);
    return DateFormat('yyyy년 MM월 dd일').format(date) + ' ($day)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent),
          onPressed: () async {
            await _saveRoutines(); // ✅ 뒤로가기 시 저장
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _addRoutineDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _dateString(today),
                  style: const TextStyle(fontSize: 18, color: Colors.greenAccent),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 18, color: Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 8),
            Text("💰 코인: $coins",
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final r = routines[index];
                  return GestureDetector(
                    onTap: () => _toggleRoutine(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: r.isDone
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${index + 1}. ${r.emoji} ${r.title}",
                              style: TextStyle(
                                color: r.isDone
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 16,
                                decoration: r.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationThickness: 2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            r.isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRoutineDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedEmoji = '🌟';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("루틴 추가",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "루틴 내용을 입력하세요",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['💪', '📖', '💊', '✅', '📗', '💧', '🧘', '🌙']
                  .map((e) => GestureDetector(
                onTap: () => setState(() => selectedEmoji = e),
                child: Text(e, style: const TextStyle(fontSize: 24)),
              ))
                  .toList(),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              setState(() {
                final insertIndex = routines.indexWhere((r) => r.isDone == true);
                if (insertIndex == -1) {
                  routines.add(Routine(
                      title: controller.text.trim(), emoji: selectedEmoji));
                } else {
                  routines.insert(
                      insertIndex,
                      Routine(
                          title: controller.text.trim(), emoji: selectedEmoji));
                }
              });
              await _saveRoutines(); // ✅ 새 루틴 추가 시 저장
              Navigator.pop(ctx);
            },
            child: const Text("추가",
                style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }
}
