import 'package:flutter/material.dart';
import 'vilage_hub_page.dart'; // 🔥 추가 — 같은 폴더에 있는 페이지 import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로그인/회원가입 예제',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainPage(),
    );
  }
}

/// ✅ 메인 화면
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('메인 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 회원가입 페이지
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String? _errorMessage;

  bool validatePassword(String password) {
    final regex =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,20}$');
    return regex.hasMatch(password);
  }

  void _signUp() {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    setState(() {
      if (id.isEmpty || pw.isEmpty) {
        _errorMessage = '아이디 또는 비밀번호를 입력해주세요.';
      } else if (!validatePassword(pw)) {
        _errorMessage = '비밀번호는 8~20자이며 영문, 숫자, 특수문자를 포함해야 합니다.';
      } else {
        _errorMessage = null;
      }
    });

    if (_errorMessage != null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입이 완료되었습니다!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WelcomePage(userId: id)),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                child: const Text('회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String? _errorMessage;

  void _login() {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();

    setState(() {
      if (id.isEmpty || pw.isEmpty) {
        _errorMessage = '아이디와 비밀번호를 입력해주세요.';
      } else {
        _errorMessage = null;
      }
    });

    if (_errorMessage != null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$id 님, 로그인 성공!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WelcomePage(userId: id)),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: '아이디'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호'),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text('로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 어서오세요 화면 → village_hub_page.dart로 이동
class WelcomePage extends StatelessWidget {
  final String userId;
  const WelcomePage({super.key, required this.userId});

  void _goNextPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const VillageHubPage()), // 🔥 변경됨
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _goNextPage(context),
      child: Scaffold(
        appBar: AppBar(title: const Text('환영합니다')),
        body: Center(
          child: Text(
            '어서오세요 $userId 님!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
