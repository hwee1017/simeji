import 'package:flutter/material.dart';

class RoomFurniturePage extends StatefulWidget {
  final Map<String, String>? selectedFurniture; // 'sofa', 'wall', 'desk', 'floor', 'background'

  const RoomFurniturePage({super.key, this.selectedFurniture});

  @override
  State<RoomFurniturePage> createState() => _RoomFurniturePageState();
}

class _RoomFurniturePageState extends State<RoomFurniturePage> {
  List<String> categories = ['소파', '벽', '책상', '바닥', '배경'];
  String selectedCategory = '소파';

  Map<String, String> selected = {
    '소파': 'assets/sofa1.png',
    '벽': 'assets/wall1.png',
    '책상': 'assets/desk1.png',
    '바닥': 'assets/floor.png',
    '배경': 'assets/background1.png',
  };

  final Map<String, List<String>> furnitureImages = {
    '소파': ['assets/sofa1.png', 'assets/sofa2.png'],
    '벽': ['assets/wall1.png', 'assets/wall2.png'],
    '책상': ['assets/desk1.png', 'assets/desk2.png'],
    '바닥': ['assets/floor.png', 'assets/floor2.png'],
    '배경': ['assets/background1.png', 'assets/background2.png'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.selectedFurniture != null) {
      selected = {
        '소파': widget.selectedFurniture!['sofa'] ?? selected['소파']!,
        '벽': widget.selectedFurniture!['wall'] ?? selected['벽']!,
        '책상': widget.selectedFurniture!['desk'] ?? selected['책상']!,
        '바닥': widget.selectedFurniture!['floor'] ?? selected['바닥']!,
        '배경': widget.selectedFurniture!['background'] ?? selected['배경']!,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> items = furnitureImages[selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('가구 선택'),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context, {
              'sofa': selected['소파'],
              'wall': selected['벽'],
              'desk': selected['책상'],
              'floor': selected['바닥'],
              'background': selected['배경'],
            });
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: Row(
        children: [
          // 세로 탭
          Container(
            width: 80,
            color: Colors.grey.shade200,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) {
                String cat = categories[i];
                bool isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 아이템 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                String path = items[i];
                bool isSelected = path == selected[selectedCategory];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selected[selectedCategory] = path;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade400, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(path, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
