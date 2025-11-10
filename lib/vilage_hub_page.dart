// lib/village_hub_page.dart
import 'package:completever/study_room/study_room_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'store_page.dart'; // 상점 화면
import 'Setting.dart';
import 'main.dart';
import 'study_room/study_room_page.dart';
import 'services/user_hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VillageHubPage extends StatefulWidget {
  final String? hair;
  final String? closet;
  final String? face;
  final RoomState? roomState;

  const VillageHubPage({
    super.key,
    this.hair,
    this.closet,
    this.face,
    this.roomState,
  });

  @override
  State<VillageHubPage> createState() => _VillageHubPageState();
}

class _VillageHubPageState extends State<VillageHubPage> {
  String? hair;
  String? closet;
  String? face;

  String? userName;
  String? userId;
  // int coin;

  late RoomState roomState; // 현재 가구/배경/바닥 상태

  @override
  void initState() {
    super.initState();
    hair = widget.hair ?? 'assets/hair1.png';
    closet = widget.closet ?? 'assets/closet1.png';
    face = widget.face ?? 'assets/face1.png';
    roomState = widget.roomState ??
        RoomState(
          background: 'assets/background1.png',
          floor: 'assets/floor.png',
          sofa: 'assets/sofa1.png',
          wall: 'assets/wall1.png',
          desk: 'assets/desk1.png',
        );
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      userName = UserHiveService.getUserName();
      userId = UserHiveService.getUserId();
      // coin = UserHiveService().getCoin();
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text('마을'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/setting.png', // 설정 아이콘
              width: 28,
              height: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 배경 (Y자 길)
          Positioned.fill(child: CustomPaint(painter: _RoadPainter())),

          // 집 타일
          Positioned(
            right: -30,
            top: 50,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MainScreen(
                      hair: hair,
                      closet: closet,
                      face: face,
                      roomState: roomState,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    hair = result['hair'];
                    closet = result['closet'];
                    face = result['face'];

                    // 가구 정보도 반영
                    if (result['roomState'] != null) {
                      roomState = result['roomState'];
                    }
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/home.png', width: 230, height: 230),
                  const SizedBox(height: 8),
                  const Text('집', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 독서실 타일
          Positioned(
            left: -40,
            top: 90,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudyRoomPage()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/studycafe.png',
                    width: 290,
                    height: 290,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '독서실',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 상점 타일
          Positioned(
            left: 10,
            bottom: 120,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StorePage(
                      hair: hair,
                      closet: closet,
                      face: face,
                    ),
                  ),
                );

                if (result != null) {
                  setState(() {
                    hair = result['hair'];
                    closet = result['closet'];
                    face = result['face'];
                    if (result['roomState'] != null) {
                      roomState = result['roomState']; // roomState 적용
                    }
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/shop.png',
                    width: 230,
                    height: 230,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '상점',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 프로필 카드
          Positioned(
            right: 16,
            bottom: 24,
            child: _ProfileCard(
              name: userName!,      // 사용자 ID를 이름으로 표시
              userId: userId!,
              etc: '코인/레벨 등',        // "크레딧"을 "코인"으로 변경
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String name;
  final String userId;
  final String etc;
  const _ProfileCard({
    required this.name,
    required this.userId,
    required this.etc,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/profile1.png'),
            ),
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

/// 심플한 Y자 길 페인터
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
