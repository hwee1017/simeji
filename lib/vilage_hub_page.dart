// lib/village_hub_page.dart
import 'package:flutter/material.dart';
import 'store_page.dart'; // 상점 화면
import 'Setting.dart';
import 'main.dart';


class VillageHubPage extends StatelessWidget {
  const VillageHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마을'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면 이동 (필요시)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // 배경(간단 Y자 길 표현 – 생략 가능)
          Positioned.fill(child: CustomPaint(painter: _RoadPainter())),

          // #myhome 타일 (오른쪽 위)
          Positioned(
            right: 20,
            top: 40,
            child: _VillageTile(
              icon: Icons.home_rounded,
              label: '#myhome',
              onTap: () {
                // main.dart로 이동
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()), // ✅ main.dart의 MyApp으로 이동
                      (route) => false, // 기존 스택 전부 제거
                );
              },
            ),
          ),

          // #독서실 타일 (왼쪽 중단)
          Positioned(
            left: 20,
            top: 160,
            child: _VillageTile(
              icon: Icons.local_library_rounded,
              label: '#독서실',
              onTap: () {
                // TODO: 독서실 화면으로 이동(아직 없으면 스낵바)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('독서실은 준비중입니다.')),
                );
              },
            ),
          ),

          // #상점 타일 (왼쪽 하단)
          Positioned(
            left: 20,
            bottom: 40,
            child: _VillageTile(
              icon: Icons.storefront_rounded,
              label: '#상점',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StorePage()),
                );
              },
            ),
          ),

          // 오른쪽 하단 프로필 카드(간단 UI)
          Positioned(
            right: 16,
            bottom: 24,
            child: _ProfileCard(
              name: '조사', // TODO: 실제 유저명 연결
              userId: 'user_001',
              etc: '크레딧/레벨 등',
            ),
          ),
        ],
      ),
    );
  }
}

class _VillageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _VillageTile({required this.icon, required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 140,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String userId;
  final String etc;
  const _ProfileCard({required this.name, required this.userId, required this.etc, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            CircleAvatar(radius: 18, child: Icon(Icons.person)),
            SizedBox(width: 8),
            Text('프로필', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 16),
          Text('이름: $name'),
          Text('id : $userId'),
          Text('기타: $etc'),
        ],
      ),
    );
  }
}

/// 아주 심플한 Y자 길(회색 영역) 페인터 – 필요 없으면 삭제해도 됨.
class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade200;
    final path = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.55, size.height)
      ..lineTo(size.width * 0.7, size.height * 0.55)
      ..lineTo(size.width * 0.6, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}