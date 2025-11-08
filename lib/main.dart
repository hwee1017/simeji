import 'dart:async';
import 'package:flutter/material.dart';
import 'closestpage.dart';
import 'vilage_hub_page.dart';
import 'LogIn.dart';
import 'Chat.dart'; // 💡 lib/Chat.dart 파일에서 ChatScreen을 불러오기 위해 추가

void main() {
  runApp(const MyApp());
}

class CharacterState {
  String hair;
  String closet;
  String face;
  CharacterState({
    this.hair = 'assets/hair1.png',
    this.closet = 'assets/closet1.png',
    this.face = 'assets/face1.png',
  });
}


class MyApp extends StatelessWidget {
  final String? hair;
  final String? closet;
  final String? face;
  const MyApp({super.key, this.hair, this.closet, this.face});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Character Room',
      theme: ThemeData(useMaterial3: true),
      home: MainPage(),
    );
  }
}

// =======================
// 🏠 메인화면
// =======================
class MainScreen extends StatefulWidget {
  final String? hair;
  final String? closet;
  final String? face;
  const MainScreen({super.key, this.hair, this.closet, this.face});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isListening = false;
  bool showEmotionPopup = false;
  String characterEmotion = '🙂';
  String defaultEmotion = '🙂';
  String? hair;
  String? closet;
  String? face;

  
  final Map<String, String> emotionFaces = {
    'angry': 'assets/angry.png',
    'annoying': 'assets/annoying.png',
    'happy': 'assets/happy.png',
    'keke': 'assets/keke.png',
    'love': 'assets/love.png',
    'sad': 'assets/sad.png',
    'surprise': 'assets/surprise.png',
    'yum': 'assets/yum.png',
  };

  void toggleListening(bool start) {
    setState(() {
      isListening = start;
    });
  }
  void hideEmotionPopup() {
    setState(() {
      showEmotionPopup = false;
    });
  }

  @override
  void initState() {
    super.initState();
    hair = widget.hair ?? 'assets/hair1.png';
    closet = widget.closet ?? 'assets/closet1.png';
    face = widget.face ?? 'assets/face1.png';
  }
  void changeEmotionTemporarily(String newEmotion) {
    setState(() {
      characterEmotion = newEmotion;
    });

    // 3초 뒤 원래 표정으로 복귀
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          characterEmotion = defaultEmotion;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 방'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pop(context, {
                'hair': hair,
                'closet': closet,
                'face': face,
              });
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ✅ 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/room_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // ✅ 캐릭터 (중앙)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/mainchar.png',
                  height: 900,
                ),
                if(hair!=null) Image.asset(hair!,height:900),
                if(closet!=null) Image.asset(closet!,height:900),
                if (face != null) Image.asset(face!, height: 900),
                // Text(
                //   characterEmotion,
                //   style: const TextStyle(fontSize: 60),
                // ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (showEmotionPopup) hideEmotionPopup();
            },
            behavior: HitTestBehavior.translucent,

          ),
          // ✅ 감정표현 팝업
          // 감정표현 팝업
          if (showEmotionPopup)
            Positioned(
              bottom: 50,
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: SizedBox(
                  height: 120,
                  width: 320, // 카드 폭
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: emotionFaces.keys.length,
                    itemBuilder: (context, index) {
                      String emotion = emotionFaces.keys.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            face = emotionFaces[emotion]; // 얼굴 변경
                            showEmotionPopup = false;
                          });
                          Timer(const Duration(seconds: 3), () {
                            if (mounted) {
                              setState(() {
                                face = widget.face ?? 'assets/face1.png';
                              });
                            }
                          });
                        },
                        child: Container(
                          width: 80, // 각 아이템 폭
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Image.asset(
                                emotionFaces[emotion]!,
                                width: 50,
                                height: 50,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                emotion,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

        ],
      ),
      // ✅ 하단 메뉴
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.checkroom),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClosetMainScreen(
                      hair: hair,
                      closet: closet,
                      face: face,
                    ),
                  ),
                );

                // 돌아오면서 옷 정보 갱신
                if (result != null && mounted) {
                  setState(() {
                    hair = result['hair'];
                    closet = result['closet'];
                    face = result['face'];
                  });
                }
              },
            ),
            
            IconButton(
              icon: const Icon(Icons.emoji_emotions),
              onPressed: () {
                setState(() => showEmotionPopup = !showEmotionPopup);
              },
            ),
            GestureDetector(
              onLongPressStart: (_) {
                toggleListening(true);
              },
              onLongPressEnd: (_) {
                toggleListening(false);
              },
              child: Icon(
                Icons.mic,
                size: isListening ? 48 : 32,
                color: isListening ? Colors.red : Colors.black,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chair),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RoomEditScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () {
                // 이 ChatScreen은 Chat.dart에서 가져온 실제 채팅 화면입니다.
                // (단, 아래에 있는 데모 ChatScreen과 이름 충돌이 발생할 수 있으니 주의)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// ✅ 옷장 슬롯 화면
class ClosetMainScreen extends StatefulWidget {
  final String? hair;
  final String? closet;
  final String? face;

  const ClosetMainScreen({super.key,this.hair, this.closet, this.face});

  @override
  State<ClosetMainScreen> createState() => _ClosetMainScreenState();
}

class _ClosetMainScreenState extends State<ClosetMainScreen> {
  List<String> categories = ['헤어', '옷', '얼굴'];
  String selectedCategory = '헤어';

  String? selectedHair;
  String? selectedCloset;
  String? selectedFace;

  final Map<String, List<String>> clothesImages = {
    '헤어': ['assets/hair1.png', 'assets/hair2.png'],
    '옷': ['assets/closet1.png', 'assets/closet2.png'],
    '얼굴': ['assets/face1.png', 'assets/face2.png'],
  };

  // @override
  // void initState() {
  //   super.initState();
  //   selectedHair = widget.hair;
  //   selectedCloset = widget.closet;
  //   selectedFace = widget.face;
  // }

  int unlockedSlots = 1; // 기본 슬롯 1개만 열려 있음
  int selectedSlot = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('옷장')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2x2 슬롯
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 4, // 최대 4개의 슬롯
          itemBuilder: (context, index) {
            bool unlocked = index < unlockedSlots;
            return GestureDetector(
              onTap: unlocked
                  ? () => setState(() => selectedSlot = index)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: selectedSlot == index
                        ? Colors.blueAccent
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: unlocked
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 캐릭터 미리보기
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/mainchar.png', height: 100),
                          Image.asset(selectedHair ?? 'assets/hair1.png', height: 100),
                          Image.asset(selectedCloset ?? 'assets/closet1.png', height: 100),
                          Image.asset(selectedFace ?? 'assets/face1.png', height: 100),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('슬롯 ${index + 1}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                                onPressed: () async {
                                  // 갈아입기 화면으로 이동
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ClosetPage(
                                        hair:selectedHair ?? 'assets/hair1.png',
                                        closet:selectedCloset ?? 'assets/closet1.png',
                                        face:selectedFace ?? 'assets/face1.png',
                                      ),
                                    ),
                                  );

                                  // 돌아오면서 선택된 옷 정보 적용
                                  if (result != null && mounted) {
                                    setState(() {
                                      selectedHair = result['hair'];
                                      selectedCloset = result['closet'];
                                      selectedFace = result['face'];
                                    });
                                  }
                                },
                                child: const Text('갈아입기'),
                              ),
                        ElevatedButton(
                                onPressed: () {
                                  // 선택된 슬롯 정보 VillageHubPage/MainScreen으로 전달
                                  Navigator.pop(context, {
                                    'hair': selectedHair ?? 'assets/hair1.png',
                                    'closet':
                                        selectedCloset ?? 'assets/closet1.png',
                                    'face': selectedFace ?? 'assets/face1.png',
                                  });

                                  // 선택 완료 스낵바
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('슬롯 ${index + 1} 선택됨'),
                                    ),
                                  );
                                },
                                child: const Text('선택'),
                              ),

                      ],
                    ),
                  ],
                )
                    : const Icon(Icons.lock, size: 60, color: Colors.grey),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 슬롯 해제 (상점 구매 시)
          if (unlockedSlots < 4) {
            setState(() => unlockedSlots++);
          }
        },
        label: const Text('슬롯 해제'),
        icon: const Icon(Icons.lock_open),
      ),
    );
  }
}




// =======================
// 🪑 방 배치
// =======================
class RoomEditScreen extends StatelessWidget {
  const RoomEditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('방 배치')),
      body: const Center(child: Text('가구를 배치하는 화면입니다.')),
    );
  }
}

