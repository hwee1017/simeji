import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'vilage_hub_page.dart';
import 'services/store_hive_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  String? _errorMessage;
  bool _busy = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();
    //await StoreHiveService.seedDefaultsIfEmpty(); //작동 코드(이전 기록 hive에 남은 상태) -> TEST 끝나고 교체
    await StoreHiveService.resetToFactory(); // 코인=1000, 보유아이템=[cloth1, face1, face2, hair1]로 강제 초기화


    setState(() => _errorMessage = null);
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _errorMessage = '아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      // 안전벨트: 혹시 개발 중 실수로 박스를 닫았어도 여기서 보장
      if (!Hive.isBoxOpen('coins'))    { await Hive.openBox('coins'); }
      if (!Hive.isBoxOpen('inventory')){ await Hive.openBox('inventory'); }

      final coinBox = Hive.box('coins');
      final invBox  = Hive.box('inventory');

      // 초기 상태 보장
      coinBox.put('coin', coinBox.get('coin', defaultValue: 1000) as int);
      final defaults = <String>['cloth1', 'face1', 'face2', 'hair1'];
      final current  = List<String>.from(invBox.get('items', defaultValue: []));
      bool changed = false;
      for (final x in defaults) {
        if (!current.contains(x)) { current.add(x); changed = true; }
      }
      if (changed) invBox.put('items', current);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VillageHubPage(userId: id)),
      );
    } catch (e) {
      setState(() => _errorMessage = '로그인 처리 중 오류: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _idController, decoration: const InputDecoration(labelText: '아이디')),
            const SizedBox(height: 12),
            TextField(controller: _pwController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true, onSubmitted: (_) => _login()),
            const SizedBox(height: 12),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _login,
                child: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('로그인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
