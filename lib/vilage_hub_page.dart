// lib/village_hub_page.dart
import 'package:flutter/material.dart';
import 'store_page.dart'; // 상점 화면
import 'Setting.dart';
import 'main.dart';
import 'pages/study_room_page.dart';

class VillageHubPage extends StatefulWidget {
  final String? hair;
  final String? closet;
  final String? face;
  final RoomState? roomState; // ✅ 추가

  const VillageHubPage({super.key, this.hair, this.closet, this.face, this.roomState});

  @override
  State<VillageHubPage> createState() => _VillageHubPageState();
}

class _VillageHubPageState extends State<VillageHubPage> {
  String? hair;
  String? closet;
  String? face;

  late RoomState roomState; // 현재 가구/배경/바닥 상태

  @override
  void initState() {
    super.initState();
    hair = widget.hair ?? 'assets/hair1.png';
    closet = widget.closet ?? 'assets/closet1.png';
    face = widget.face ?? 'assets/face1.png';
    roomState = widget.roomState ?? RoomState(
      background: 'assets/background1.png',
      floor: 'assets/floor.png',
      sofa: 'assets/sofa1.png',
      wall: 'assets/wall1.png',
      desk: 'assets/desk1.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마을'),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/setting.png', // 👉 넣고 싶은 이미지 경로
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
          // 배경(간단 Y자 길 표현 – 생략 가능)
          Positioned.fill(child: CustomPaint(painter: _RoadPainter())),

          // #myhome 타일
          // #myhome 타일
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

                    // ✅ 가구 정보도 반영
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
          // #독서실 타일 (왼쪽 중단)
          Positioned(
            left: -40,
            top: 90,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudyRoomPage()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/studycafe.png', // 원하는 이미지
                    width: 290, // 크기 조정 가능
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


          // #상점 타일 (왼쪽 하단)
          Positioned(
  left: 10,
  bottom: 120,
  child: GestureDetector(
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StorePage(hair: hair, closet: closet, face: face),
        ),
      );

      if (result != null) {
        setState(() {
          hair = result['hair'];
          closet = result['closet'];
          face = result['face'];
          if (result['roomState'] != null) {
            roomState = result['roomState']; // ✅ roomState 적용
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
   final String imagePath; // 이미지 경로
  final String label;
  final VoidCallback onTap;

  const _VillageTile({
    required this.imagePath,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Image.asset(
            imagePath, // 기존 icon 대신 imagePath 사용
            width: 64, // 원하는 크기로 조정
            height: 64,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
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
            CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/profile1.png'), // 이미지 경로
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