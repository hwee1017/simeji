import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'store_page.dart'; // 상점 화면
import 'Setting.dart';
import 'main.dart';
import 'study_room/study_room_page.dart';

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
  late RoomState roomState;

  // 프로필 관련 변수
  String name = '로딩 중...';
  String userId = '';
  String etc = '';
  bool isLoading = true;

  final Dio dio = Dio();

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

    // 페이지 진입 시 프로필 API 호출
    fetchProfile();
  }

  /// 프로필 API 호출
  // Future<void> fetchProfile() async {
  //   try {
  //     final response = await dio.get('https://api.example.com/profile');
  //     final data = response.data;

  //     setState(() {
  //       name = data['name'] ?? '이름 없음';
  //       userId = data['userId'] ?? 'unknown';
  //       etc = data['etc'] ?? '정보 없음';
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       name = '불러오기 실패';
  //       etc = e.toString();
  //       isLoading = false;
  //     });
  //   }
  // }
  void fetchProfile() {
    print("✅ fetchProfile implemented!!");
    name = "asdf";
    userId = "qwerqwer";
    etc = "213";
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/stopwatch.png', width: 28, height: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('마을'),
        actions: [
          IconButton(
            icon: Image.asset('assets/setting.png', width: 28, height: 28),
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
          // 배경 도로
          Positioned.fill(child: CustomPaint(painter: _RoadPainter())),

          // 집 타일
          Positioned(
            right: -30,
            top: 50,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MainScreen(
                      hair: hair,
                      closet: closet,
                      face: face,
                      roomState: roomState,
                    ),
                  ),
                ).then((_) {
                  // 돌아왔을 때 프로필 갱신
                  fetchProfile();
                });
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
                  MaterialPageRoute(builder: (_) => const StudyRoomPage()),
                ).then((_) {
                  // 돌아왔을 때 프로필 갱신
                  fetchProfile();
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/studycafe.png', width: 290, height: 290),
                  const SizedBox(height: 8),
                  const Text('독서실',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                    builder: (_) =>
                        StorePage(hair: hair, closet: closet, face: face),
                  ),
                );

                if (result != null) {
                  setState(() {
                    hair = result['hair'];
                    closet = result['closet'];
                    face = result['face'];
                    if (result['roomState'] != null) {
                      roomState = result['roomState'];
                    }
                  });
                }

                // 상점에서 돌아왔을 때 프로필 갱신
                fetchProfile();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/shop.png', width: 230, height: 230),
                  const SizedBox(height: 8),
                  const Text('상점',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 오른쪽 하단 프로필 카드
          Positioned(
            right: 16,
            bottom: 24,
            child: isLoading
                ? const CircularProgressIndicator()
                : _ProfileCard(name: name, userId: userId, etc: etc),
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
    super.key,
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
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4))
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
          Text('ID: $userId'),
          Text('기타: $etc'),
        ],
      ),
    );
  }
}

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
