import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✅ Hive 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('study_log'); // ✅ 공부 & 휴식 기록용 박스
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

  DateTime? _sessionStart; // ✅ 세션(공부 or 휴식) 시작 시각
  DateTime? _sessionEnd;   // ✅ 세션 종료 시각

  // ✅ Hive에 공부/휴식 세션 저장
  Future<void> _saveSession(String mode, DateTime start, DateTime end) async {
    final box = Hive.box('study_log');
    final existing = box.get('sessions', defaultValue: <Map>[]) as List;
    final updated = List<Map>.from(existing)
      ..add({
        'mode': mode,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      });
    await box.put('sessions', updated);
    debugPrint("💾 Hive 저장 완료 ($mode): $start ~ $end");
  }

  // ⏱ 타이머 시작
  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _sessionStart = DateTime.now(); // ✅ 시작 시각 기록
      debugPrint("⏰ ${_mode == TimerMode.study ? '공부' : '휴식'} 시작: $_sessionStart");
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (!_isOver) {
          if (_remaining.inSeconds > 0) {
            _remaining -= const Duration(seconds: 1);
          } else {
            // 시간 초과
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
    _coins += 10;
  }

  // ☕ 휴식 초과(1분) → 코인 초기화
  void _handleRestOvertime() {
    _coins = 0;
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

  // ⏹ 정지 버튼 눌렀을 때 → 종료 시각 저장
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

  // ✅ 나가기 버튼 (현재 세션 종료 시 저장)
  Future<void> _handleExit() async {
    if (_isRunning && _sessionStart != null) {
      _sessionEnd = DateTime.now();
      await _saveSession(
        _mode == TimerMode.study ? 'study' : 'rest',
        _sessionStart!,
        _sessionEnd!,
      );
    }
    if (context.mounted) Navigator.pop(context);
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
