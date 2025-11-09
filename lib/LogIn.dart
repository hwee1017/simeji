// lib/LogIn.dart
import 'package:flutter/material.dart';
import 'vilage_hub_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 네트워크/디버그용
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('session'); // 세션 박스 (currentUserId 저장)
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

// ========================
// Hive 유저 기본값 보장
// ========================
Future<void> _ensureUserInitialized(String userId) async {
  final boxName = 'user_$userId';
  final box = await Hive.openBox(boxName);

  if (!box.containsKey('credits')) {
    await box.put('credits', 50000);
  }
  if (!box.containsKey('purchases')) {
    await box.put('purchases', <String, bool>{});
  }
  if (!box.containsKey('inventory')) {
    await box.put('inventory', <String, dynamic>{});
  }
}

Future<void> _saveCurrentSession(String userId) async {
  final session = Hive.box('session');
  await session.put('currentUserId', userId);
}

// ========================
// API 클라이언트 (스펙 준수 + 307/308 방탄)
// ========================
class Api {
  static const String base = 'https://9b84761b6716.ngrok-free.app';

  /// 명세서: [POST] /users
  /// Body: { "user_maked_ID": "...", "password": "..." }
  /// 200: { success:true, comments:"...", userID:"..." }
  /// 400: { success:false, error:{ code:"USER_MAKED_ID_CONFLICT", message:"..." } }
  /// 500: { success:false, error:{ code:"INTERNAL_ERROR", message:"서버 오류." } }
  static Future<SignUpResult> signUp({
    required String userMakedId,
    required String password,
  }) async {
    // ngrok가 /users → /users/ 로 307 던지는 걸 선제 차단
    final uri = Uri.parse('$base/users/');

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'user_maked_ID': userMakedId,
      'password': password,
    });

    try {
      // 307/308 리다이렉트 추적 (POST/바디/헤더 그대로 유지)
      final resp = await _postJsonWithRedirects(uri, headers, body);
      final text = utf8.decode(resp.bodyBytes, allowMalformed: true);

      debugPrint('[SIGNUP] status=${resp.statusCode} body=$text');

      // ===== 200 OK =====
      if (resp.statusCode == 200) {
        final m = jsonDecode(text) as Map<String, dynamic>;
        final ok = m['success'] == true;
        final userId = m['userID']?.toString();
        final comments = (m['comments'] ?? '').toString();
        if (!ok || userId == null) {
          throw ServerException('응답 형식이 올바르지 않습니다.');
        }
        return SignUpResult(success: true, userId: userId, comments: comments);
      }

      // ===== 400 Conflict (아이디 중복) =====
      if (resp.statusCode == 400) {
        final m = _tryDecode(text);
        final code = (m['error']?['code'] ?? 'USER_MAKED_ID_CONFLICT').toString();
        final msg = (m['error']?['message'] ?? '해당하는 유저의 id가 이미 존재합니다.').toString();
        throw ConflictException(code: code, message: msg);
      }

      // ===== 500 or 기타 =====
      final m = _tryDecode(text);
      final serverMsg = (m['error']?['message'] ?? '서버 오류.').toString();
      throw ServerException('(${resp.statusCode}) $serverMsg');

    } on SocketException {
      // 인터넷 권한, DNS, 오프라인 등
      throw NetworkException('네트워크 연결 실패(인터넷 권한/DNS/도메인 확인)');
    } on TimeoutException {
      throw NetworkException('요청이 지연되었습니다(타임아웃).');
    } on FormatException {
      // JSON이 아닐 때 (ngrok 에러 페이지 등)
      throw ServerException('서버 응답 파싱 실패(JSON 아님)');
    }
  }

  // ── 내부 유틸: 리다이렉트 추적 POST ─────────────────────────────
  static Future<http.Response> _postJsonWithRedirects(
      Uri uri,
      Map<String, String> headers,
      String body, {
        int maxRedirects = 5,
        Duration timeout = const Duration(seconds: 15),
      }) async {
    var current = uri;
    var hops = 0;
    final client = http.Client();
    try {
      while (true) {
        final req = http.Request('POST', current)
          ..headers.addAll(headers)
          ..body = body;

        final streamed = await client.send(req).timeout(timeout);
        final resp = await http.Response.fromStream(streamed);
        debugPrint('[POST] ${resp.request?.url} -> ${resp.statusCode}');

        final isRedirect = resp.isRedirect || resp.statusCode == 307 || resp.statusCode == 308;
        if (!isRedirect) return resp;

        if (hops++ >= maxRedirects) {
          throw ServerException('리다이렉트가 너무 많습니다.');
        }
        final loc = resp.headers['location'];
        if (loc == null || loc.isEmpty) {
          throw ServerException('리다이렉트 Location 헤더 없음');
        }

        var next = Uri.parse(loc);
        if (!next.hasScheme) next = current.resolve(loc);
        // http로 튀면 https로 강제 업그레이드 (안드 9+ cleartext 차단 회피)
        if (next.scheme == 'http') next = next.replace(scheme: 'https');
        current = next;
        // 루프 재시도 (POST/바디/헤더 동일)
      }
    } finally {
      client.close();
    }
  }

  // ── 파싱 보조 ────────────────────────────────────────────────
  static Map<String, dynamic> _tryDecode(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

// ========================
// DTO & 예외 타입
// ========================
class SignUpResult {
  final bool success;
  final String userId;
  final String comments;
  SignUpResult({
    required this.success,
    required this.userId,
    required this.comments,
  });
}

class ConflictException implements Exception {
  final String code;
  final String message;
  ConflictException({required this.code, required this.message});
  @override
  String toString() => '$code: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

// ========================
// 회원가입 페이지
// ========================
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String? _errorMessage;
  bool _loading = false;

  bool validatePassword(String password) {
    final regex = RegExp(
        r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>]).{8,20}$');
    return regex.hasMatch(password);
  }

  Future<void> _signUp() async {
    if (_loading) return;
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

    setState(() => _loading = true);
    try {
      debugPrint('[FLOW] A: signUp 시작');

      final res = await Api.signUp(userMakedId: id, password: pw);
      final issuedUserId = res.userId;
      debugPrint('[FLOW] B: signUp 성공 => $issuedUserId');

      await _ensureUserInitialized(issuedUserId);
      await _saveCurrentSession(issuedUserId);
      debugPrint('[FLOW] C: Hive 초기화/세션 저장 OK');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.comments.isEmpty ? '회원가입이 완료되었습니다!' : res.comments)),
      );

      debugPrint('[FLOW] D: 네비게이션 시작');
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WelcomePage(userId: issuedUserId)),
      );
      debugPrint('[FLOW] E: 네비게이션 완료');

    } on ConflictException catch (e) {
      setState(() => _errorMessage = e.message);          // 아이디 중복
    } on NetworkException catch (e) {
      setState(() => _errorMessage = e.message);          // 네트워크 문제
    } on ServerException catch (e) {
      setState(() => _errorMessage = e.message);          // 서버/리다이렉트 계열
    } catch (e, st) {
      debugPrint('[API ERROR] $e\n$st');
      setState(() => _errorMessage = e.toString());       // 기타
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _signUp,
                child: Text(_loading ? '처리중...' : '회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================
// 로그인 페이지 (로컬 세션만 설정)
// ========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String? _errorMessage;

  Future<void> _login() async {
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

    await _ensureUserInitialized(id);
    await _saveCurrentSession(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$id 님, 로그인 성공!')),
    );

    await Navigator.pushReplacement(
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
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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

class WelcomePage extends StatelessWidget {
  final String userId;
  const WelcomePage({super.key, required this.userId});

  void _goNextPage(BuildContext context) async {
    try {
      await Navigator.pushReplacement(
        context,
        // VillageHubPage는 세션에서 userId를 읽도록 수정된 버전 사용 권장
        MaterialPageRoute(builder: (_) => const VillageHubPage()),
      );
    } catch (e, st) {
      debugPrint('[NAV ERROR] $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네비게이션 오류: $e')),
      );
    }
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
