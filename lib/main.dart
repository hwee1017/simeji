import 'dart:async';
import 'package:flutter/material.dart';
import 'closestpage.dart';
import 'vilage_hub_page.dart';
import 'Chat.dart'; // 💡 lib/Chat.dart 파일에서 ChatScreen을 불러오기 위해 추가

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Character Room',
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

// =======================
// 🏠 메인화면
// =======================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VillageHubPage()),
              );
            },
          )
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
          if (showEmotionPopup)
            Positioned(
              bottom: 100,
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: SizedBox(
                  width: 250,
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var emoji in ['😀', '😡', '😭', '😍', '😎', '😴'])
                        GestureDetector(
                          onTap: () {
                            changeEmotionTemporarily(emoji);
                            setState(() => showEmotionPopup = false);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 40)),
                          ),
                        ),
                    ],
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
                // ClosetPage로 이동하고 선택된 옷 정보를 기다림
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClosetMainScreen(hair: hair, closet: closet, face: face),
                  ),
                );

                // 돌아올 때 옷 정보 반영
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

  @override
  void initState() {
    super.initState();
    selectedHair = widget.hair;
    selectedCloset = widget.closet;
    selectedFace = widget.face;
  }

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
                        if (selectedHair != null)
                          Image.asset(selectedHair!, height: 100),
                        if (selectedCloset != null)
                          Image.asset(selectedCloset!, height: 100),
                        if (selectedFace != null)
                          Image.asset(selectedFace!, height: 100),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('슬롯 ${index + 1}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // 옷 갈아입기 탭으로 이동
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClosetPage(
                                  hair: selectedHair,
                                  closet: selectedCloset,
                                  face: selectedFace,
                                ),
                              ),
                            );
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
                            Navigator.pop(context, {
                              'hair': selectedHair,
                              'closet': selectedCloset,
                              'face': selectedFace,
                            });
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


// // =======================
// // 👕 옷장 화면 (그림 반영 버전)
// // =======================
// class ClosetScreen extends StatefulWidget {
//   const ClosetScreen({super.key});

//   @override
//   State<ClosetScreen> createState() => _ClosetScreenState();
// }

// class _ClosetScreenState extends State<ClosetScreen> {
//   final List<String> categories = [
//     '헤어',
//     '화장',
//     '상의',
//     '하의',
//     '신발',
//     '액세서리',
//     '프로필사진',
//     '성격',
//   ];
//   String selectedCategory = '헤어';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('옷장'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Row(
//         children: [
//           // ✅ 왼쪽 캐릭터 영역
//           Expanded(
//             flex: 2,
//             child: Center(
//               child: Image.asset('assets/mainchar.png', height: 250),
//             ),
//           ),

//           // ✅ 오른쪽 탭 + 아이템 영역
//           Expanded(
//             flex: 3,
//             child: Row(
//               children: [
//                 // 세로 탭 버튼 (Column)
//                 Container(
//                   width: 80,
//                   color: Colors.grey.shade200,
//                   child: ListView.builder(
//                     itemCount: categories.length,
//                     itemBuilder: (context, index) {
//                       String name = categories[index];
//                       bool selected = name == selectedCategory;
//                       return GestureDetector(
//                         onTap: () {
//                           setState(() => selectedCategory = name);
//                         },
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(
//                             vertical: 4,
//                             horizontal: 6,
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           decoration: BoxDecoration(
//                             color: selected
//                                 ? Colors.blueAccent
//                                 : Colors.grey.shade300,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: Center(
//                             child: Text(
//                               name,
//                               style: TextStyle(
//                                 color: selected ? Colors.white : Colors.black,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),

//                 // ✅ 탭 옆 아이템 미리보기 영역
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     child: GridView.builder(
//                       itemCount: 8, // 예시 아이템 수
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                             crossAxisCount: 2, // 한 줄에 2개씩
//                             mainAxisSpacing: 10,
//                             crossAxisSpacing: 10,
//                             childAspectRatio: 1,
//                           ),
//                       itemBuilder: (context, index) {
//                         return GestureDetector(
//                           onTap: () {
//                             // TODO: 탭 클릭 시 캐릭터 의상 적용 기능
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   '$selectedCategory 아이템 ${index + 1} 선택',
//                                 ),
//                                 duration: const Duration(seconds: 1),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               border: Border.all(
//                                 color: Colors.grey.shade400,
//                                 width: 1.5,
//                               ),
//                               borderRadius: BorderRadius.circular(10),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 3,
//                                   offset: const Offset(2, 2),
//                                 ),
//                               ],
//                             ),
//                             child: const Icon(
//                               Icons.checkroom,
//                               size: 40,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),

//       // ✅ 하단 저장 버튼
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('현재 상태가 저장되었습니다!')));
//           Navigator.pop(context);
//         },
//         icon: const Icon(Icons.save),
//         label: const Text('저장'),
//       ),
//     );
//   }
// }


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



// =======================
// 🏡 마을 화면
// =======================
// class VillageScreen extends StatelessWidget {
//   const VillageScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('마을')),
//       body: const Center(child: Text('마을 화면으로 이동했습니다.')),
//     );
//   }
// }