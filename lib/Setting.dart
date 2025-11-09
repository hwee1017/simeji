import 'package:flutter/material.dart';
import 'LogIn.dart'; // LogIn 페이지 import 추가
import 'services/user_hive_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '설정 탭 예제',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int baseTime = 5;
  int extraTime = 4;

  bool isEditingBaseTime = false;
  bool isEditingExtraTime = false;

  final _baseTimeController = TextEditingController();
  final _extraTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hive에서 값 불러오기
    baseTime = UserHiveService.getBaseTime();
    extraTime = UserHiveService.getExtraTime();
  }

  @override
  void dispose() {
    _baseTimeController.dispose();
    _extraTimeController.dispose();
    super.dispose();
  }

  // Hive에 저장하는 함수
  Future<void> _saveSettings() async {
    await UserHiveService.saveSettings(baseTime: baseTime, extraTime: extraTime);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 저장되었습니다.')),
      );
    }
  }

  void _toggleBaseTimeEdit() async {
    setState(() {
      if (isEditingBaseTime) {
        final input = int.tryParse(_baseTimeController.text);
        if (input != null) baseTime = input;
      } else {
        _baseTimeController.text = baseTime.toString();
      }
      isEditingBaseTime = !isEditingBaseTime;
    });

    // “저장”을 누른 경우에만 실행
    if (!isEditingBaseTime) {
      await _saveSettings();
    }
  }

  void _toggleExtraTimeEdit() async {
    setState(() {
      if (isEditingExtraTime) {
        final input = int.tryParse(_extraTimeController.text);
        if (input != null) extraTime = input;
      } else {
        _extraTimeController.text = extraTime.toString();
      }
      isEditingExtraTime = !isEditingExtraTime;
    });

    // “저장”을 누른 경우에만 실행
    if (!isEditingExtraTime) {
      await _saveSettings();
    }
  }

  // 로그아웃 확인 다이얼로그 함수
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 기준시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isEditingBaseTime
                      ? TextField(
                    controller: _baseTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '기준 시간 (시)',
                      hintText: '예: 5',
                    ),
                  )
                      : Text(
                    '기준 시간: $baseTime시간',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _toggleBaseTimeEdit,
                  child: Text(isEditingBaseTime ? '저장' : '변경하기'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 잉여시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isEditingExtraTime
                      ? TextField(
                    controller: _extraTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '잉여 시간 (시)',
                      hintText: '예: 4',
                    ),
                  )
                      : Text(
                    '잉여 시간: $extraTime시간',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _toggleExtraTimeEdit,
                  child: Text(isEditingExtraTime ? '저장' : '변경하기'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 비밀번호 변경 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
              child: const Text('비밀번호 변경'),
            ),

            const SizedBox(height: 30),

            const Spacer(),

            // 로그아웃 버튼 (맨 아래쪽, 빨간색)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _showLogoutDialog,
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  bool validatePassword(String password) {
    final regex =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,20}$');
    return regex.hasMatch(password);
  }

  void _changePassword() {
    setState(() {
      if (!validatePassword(_newController.text)) {
        _errorMessage = '비밀번호는 8~20글자, 영문/숫자/특수문자를 포함해야 합니다.';
      } else if (_newController.text != _confirmController.text) {
        _errorMessage = '비밀번호 확인이 일치하지 않습니다.';
      } else {
        _errorMessage = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }
}
