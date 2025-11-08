import 'package:flutter/material.dart';
class ClosetPage extends StatefulWidget {
  final String? hair;
  final String? closet;
  final String? face;

  const ClosetPage({super.key, this.hair, this.closet, this.face});

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  List<String> categories = ['헤어', '옷', '얼굴'];
  String selectedCategory = '헤어';

  String? selectedHair='assets/hair1.png';
  String? selectedCloset='assets/closet1.png';
  String? selectedFace='assets/face1.png';

  final Map<String, List<String>> clothesImages = {
    '헤어': ['assets/hair1.png', 'assets/hair2.png'],
    '옷': ['assets/closet1.png', 'assets/closet2.png'],
    '얼굴': ['assets/face1.png', 'assets/face2.png'],
  };

  @override
  void initState() {
    super.initState();
    selectedHair = widget.hair ?? 'assets/hair1.png';
    selectedCloset = widget.closet?? 'assets/closet1.png';
    selectedFace = widget.face?? 'assets/face1.png';
  }

  @override
  Widget build(BuildContext context) {
    List<String> selectedImages = clothesImages[selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('옷장'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context, {
              'hair': selectedHair,
              'closet': selectedCloset,
              'face': selectedFace,
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/arrow.png', // 원하는 이미지
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          // ✅ 왼쪽 캐릭터 영역
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/mainchar.png', height: 250),
                  if (selectedHair != null)
                    Image.asset(selectedHair!, height: 250),
                  if (selectedCloset != null)
                    Image.asset(selectedCloset!, height: 250),
                  if (selectedFace != null)
                    Image.asset(selectedFace!, height: 250),
                ],
              ),
            ),
          ),

          // ✅ 오른쪽 탭 + 아이템
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // 세로 탭
                Container(
                  width: 80,
                  color: Colors.grey.shade200,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      String name = categories[index];
                      bool selected = name == selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = name);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 6,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blueAccent
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ✅ 아이템 그리드
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: selectedImages.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      String imagePath = selectedImages[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selectedCategory == '헤어')
                              selectedHair = imagePath;
                            if (selectedCategory == '옷')
                              selectedCloset = imagePath;
                            if (selectedCategory == '얼굴')
                              selectedFace = imagePath;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
