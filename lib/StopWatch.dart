import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('study_log'); // 공부/휴식 기록용 박스
  runApp(const StopwatchApp());
}

class StopwatchApp extends StatelessWidget {
  const StopwatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공부 스톱워치',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blueAccent,
        useMaterial3: true,
      ),
      home: const StudyTimerScreen(),
    );
  }
}

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

enum TimerMode { study, rest }

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 25);
  Duration _studyTime = const Duration(minutes: 25);
  Duration _restTime = const Duration(minutes: 5);
  Duration _overTime = Duration.zero;

  TimerMode _mode = TimerMode.study;
  bool _isRunning = false;
  bool _isOver = false;
  bool _hasShownOverMessage = false;
  int _coins = 0;

  DateTime? _sessionStart;
  DateTime? _sessionEnd;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('study_log');
    setState(() {
      _coins = box.get('coins', defaultValue: 0);
    });
  }

  // ✅ 코인 저장
  Future<void> _saveCoins() async {
    final box = Hive.box('study_log');
    await box.put('coins', _coins);
  }

  // ✅ 세션 저장
  Future<void> _saveSession(String mode, DateTime start, DateTime end) async {
    final box = Hive.box('study_log');
    final existing = box.get('sessions', defaultValue: <Map>[]) as List;
    final updated = List<Map>.from(existing)
      ..add({
        'mode': mode,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'coins': _coins,
      });
    await box.put('sessions', updated);
    debugPrint("💾 Hive 저장 완료 ($mode): $start ~ $end (코인: $_coins)");

    // ✅ (선택) 서버 업로드 예시
    try {
      await http.post(
        Uri.parse('https://example.com/api/session/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mode': mode,
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
          'coins': _coins,
        }),
      );
    } catch (e) {
      debugPrint("서버 업로드 실패: $e");
    }
  }

  // ⏱ 타이머 시작
  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _sessionStart = DateTime.now();
      debugPrint("⏰ ${_mode == TimerMode.study ? '공부' : '휴식'} 시작: $_sessionStart");
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (!_isOver) {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            _isOver = true;
            _overTime = const Duration(seconds: 1);
            if (_mode == TimerMode.study) {
              _handleStudyComplete();
            }
          }
        } else {
          _overTime += const Duration(seconds: 1);
          if (_mode == TimerMode.rest &&
              _overTime >= const Duration(minutes: 1) &&
              !_hasShownOverMessage) {
            _handleRestOvertime();
          }
        }
      });
    });
  }

  // 🎓 공부 완료 → 코인 +10
  void _handleStudyComplete() {
    setState(() {
      _coins += 10;
    });
    _saveCoins();
  }

  // ☕ 휴식 초과(1분) → 코인 초기화
  void _handleRestOvertime() {
    setState(() {
      _coins = 0;
    });
    _saveCoins();
    _hasShownOverMessage = true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '휴식 시간이 1분 초과되어 코인이 초기화됩니다. 💥',
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ⏹ 정지 버튼
  void _stopTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_sessionStart != null) {
      _sessionEnd = DateTime.now();
      await _saveSession(
        _mode == TimerMode.study ? 'study' : 'rest',
        _sessionStart!,
        _sessionEnd!,
      );
      debugPrint("🛑 ${_mode == TimerMode.study ? '공부' : '휴식'} 종료: $_sessionEnd");
    }
  }

  // 🔄 리셋
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = _mode == TimerMode.study ? _studyTime : _restTime;
      _overTime = Duration.zero;
      _isRunning = false;
      _isOver = false;
      _hasShownOverMessage = false;
    });
  }

  // 🔁 공부 ↔ 휴식 전환
  void _switchMode() {
    _timer?.cancel();

    setState(() {
      _mode = _mode == TimerMode.study ? TimerMode.rest : TimerMode.study;
      _remaining = _mode == TimerMode.study ? _studyTime : _restTime;
      _isRunning = false;
      _isOver = false;
      _overTime = Duration.zero;
      _hasShownOverMessage = false;
    });
  }

  // ⏰ 시간 포맷
  String _formatTime() {
    if (!_isOver) {
      final m = (_remaining.inSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
      return "$m:$s";
    } else {
      final m = (_overTime.inSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_overTime.inSeconds % 60).toString().padLeft(2, '0');
      return "+$m:$s";
    }
  }

  // ⚙️ 시간 설정 다이얼로그
  Future<void> _showTimeSettingDialog() async {
    final studyController =
    TextEditingController(text: _studyTime.inMinutes.toString());
    final restController =
    TextEditingController(text: _restTime.inMinutes.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("시간 설정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "공부 시간 (분)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: restController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "휴식 시간 (분)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              final study = int.tryParse(studyController.text) ?? 25;
              final rest = int.tryParse(restController.text) ?? 5;
              setState(() {
                _studyTime = Duration(minutes: study);
                _restTime = Duration(minutes: rest);
                _remaining =
                _mode == TimerMode.study ? _studyTime : _restTime;
              });
              Navigator.pop(ctx);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // ✅ 나가기 버튼
  Future<void> _handleExit() async {
    if (_isRunning && _sessionStart != null) {
      _sessionEnd = DateTime.now();
      await _saveSession(
        _mode == TimerMode.study ? 'study' : 'rest',
        _sessionStart!,
        _sessionEnd!,
      );
    }
    await _saveCoins();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRunning && _sessionStart != null) {
      _sessionEnd = DateTime.now();
      _saveSession(
        _mode == TimerMode.study ? 'study' : 'rest',
        _sessionStart!,
        _sessionEnd!,
      );
    }
    _saveCoins();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStudy = _mode == TimerMode.study;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _handleExit,
        ),
        title: Text(isStudy ? '공부 중 ⏱' : '휴식 중 ☕'),
        actions: [
          IconButton(
            onPressed: _showTimeSettingDialog,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudyHistoryPage()),
              );
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(),
              style: TextStyle(
                fontSize: 60,
                color: _isOver
                    ? Colors.redAccent
                    : (isStudy ? Colors.blue : Colors.green),
              ),
            ),
            const SizedBox(height: 30),
            Text("💰 코인: $_coins", style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                  child: Text(_isRunning ? '정지' : '시작'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _resetTimer, child: const Text('리셋')),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _switchMode,
                  child: Text(isStudy ? '휴식 시작' : '공부 시작'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudyHistoryPage extends StatelessWidget {
  const StudyHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('study_log');
    final sessions = List<Map>.from(box.get('sessions', defaultValue: []));

    return Scaffold(
      appBar: AppBar(title: const Text('공부 기록')),
      body: sessions.isEmpty
          ? const Center(child: Text('기록이 없습니다 😅'))
          : ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final s = sessions[index];
          return ListTile(
            leading: Icon(
              s['mode'] == 'study'
                  ? Icons.book
                  : Icons.coffee,
              color: s['mode'] == 'study'
                  ? Colors.blue
                  : Colors.green,
            ),
            title: Text(s['mode'] == 'study' ? '📘 공부' : '☕ 휴식'),
            subtitle: Text(
              "${s['start']} ~ ${s['end']}\n💰 코인: ${s['coins'] ?? 0}",
            ),
          );
        },
      ),
    );
  }
}