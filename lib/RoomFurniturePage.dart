import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/store_hive_service.dart';

/// 가구 기본값 상수
class FurnitureDefaults {
  static const Map<String, String> defaults = {
    '소파': 'assets/sofa1.png',
    '벽': 'assets/wall1.png',
    '책상': 'assets/desk1.png',
    '바닥': 'assets/floor.png',
    '배경': 'assets/background1.png',
  };

  // ✅ 한글 → 영문 변환용
  static const Map<String, String> keyMapping = {
    '소파': 'sofa',
    '벽': 'wall',
    '책상': 'desk',
    '바닥': 'floor',
    '배경': 'background',
  };

  // ✅ 영문 → 한글 변환용
  static const Map<String, String> reverseKeyMapping = {
    'sofa': '소파',
    'wall': '벽',
    'desk': '책상',
    'floor': '바닥',
    'background': '배경',
  };
}

class RoomFurniturePage extends StatefulWidget {
  final Map<String, String>? selectedFurniture;

  const RoomFurniturePage({super.key, this.selectedFurniture});

  @override
  State<RoomFurniturePage> createState() => _RoomFurniturePageState();
}

class _RoomFurniturePageState extends State<RoomFurniturePage> {
  final List<String> categories = ['소파', '벽', '책상', '바닥', '배경'];
  String selectedCategory = '소파';

  final Map<String, List<String>> furnitureImages = {
    '소파': ['assets/sofa1.png', 'assets/sofa2.png'],
    '벽': ['assets/wall1.png', 'assets/wall2.png'],
    '책상': ['assets/desk1.png', 'assets/desk2.png'],
    '바닥': ['assets/floor.png', 'assets/floor2.png'],
    '배경': ['assets/background1.png', 'assets/background2.png'],
  };

  // ✅ 슬롯 관리
  int selectedSlot = 1;
  int unlockedSlots = 1; // 기본 1개 슬롯만 해금
  late Map<String, String> selected;

  // ✅ 슬롯별 가구 상태 (슬롯 번호 → 가구 맵)
  Map<int, Map<String, String>> slotFurniture = {};

  List<String> purchasedIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// ✅ 초기화 (에러 처리 포함)
  Future<void> _initialize() async {
    try {
      await StoreHiveService.init();
      await StoreHiveService.seedDefaultsIfEmpty();

      purchasedIds = StoreHiveService.getPurchasedIds();

      // 슬롯 데이터 로드
      await _loadSlots();

      // 해금된 슬롯 수 로드
      await _loadUnlockedSlots();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('초기화 실패: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '데이터를 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  /// ✅ 슬롯별 Hive 데이터 로드
  Future<void> _loadSlots() async {
    try {
      final box = await Hive.openBox('room_slots');

      for (int i = 1; i <= 4; i++) {
        final data = box.get('slot_$i');
        if (data != null && data is Map) {
          slotFurniture[i] = Map<String, String>.from(data);
        } else {
          slotFurniture[i] = Map<String, String>.from(FurnitureDefaults.defaults);
        }
      }

      // 현재 선택된 슬롯의 데이터 로드
      selected = Map<String, String>.from(slotFurniture[selectedSlot] ?? FurnitureDefaults.defaults);
    } catch (e) {
      debugPrint('슬롯 로드 실패: $e');
      // 기본값으로 초기화
      for (int i = 1; i <= 4; i++) {
        slotFurniture[i] = Map<String, String>.from(FurnitureDefaults.defaults);
      }
      selected = Map<String, String>.from(FurnitureDefaults.defaults);
    }
  }

  /// ✅ 해금된 슬롯 수 로드
  Future<void> _loadUnlockedSlots() async {
    try {
      final box = await Hive.openBox('room_slots');
      unlockedSlots = box.get('unlocked_slots', defaultValue: 1) as int;
    } catch (e) {
      debugPrint('해금 슬롯 로드 실패: $e');
      unlockedSlots = 1;
    }
  }

  /// ✅ 슬롯 저장
  Future<void> _saveSlot(int slot) async {
    try {
      final box = await Hive.openBox('room_slots');
      await box.put('slot_$slot', selected);
      debugPrint('슬롯 $slot 저장 완료');
    } catch (e) {
      debugPrint('슬롯 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다.')),
        );
      }
    }
  }

  /// ✅ 슬롯 해금 (상점에서 구매 시 호출)
  Future<void> unlockNextSlot() async {
    if (unlockedSlots >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 슬롯이 이미 해금되었습니다.')),
      );
      return;
    }

    try {
      final box = await Hive.openBox('room_slots');
      setState(() {
        unlockedSlots++;
      });
      await box.put('unlocked_slots', unlockedSlots);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬롯 $unlockedSlots이(가) 해금되었습니다!')),
        );
      }
    } catch (e) {
      debugPrint('슬롯 해금 실패: $e');
    }
  }

  /// ✅ 공장 초기화 (테스트용)
  Future<void> resetToFactory() async {
    try {
      final box = await Hive.openBox('room_slots');
      for (int i = 1; i <= 4; i++) {
        await box.put('slot_$i', FurnitureDefaults.defaults);
      }
      await box.put('unlocked_slots', 1);

      setState(() {
        slotFurniture = {
          for (int i = 1; i <= 4; i++)
            i: Map<String, String>.from(FurnitureDefaults.defaults),
        };
        unlockedSlots = 1;
        selectedSlot = 1;
        selected = Map<String, String>.from(FurnitureDefaults.defaults);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 슬롯이 초기화되었습니다.')),
        );
      }
    } catch (e) {
      debugPrint('초기화 실패: $e');
    }
  }

  /// ✅ 구매 여부 확인
  bool _isUnlocked(String path) {
    try {
      final filename = path.split('/').last;
      final id = filename.split('.').first;
      if (id.endsWith('1')) return true;
      return purchasedIds.contains(id);
    } catch (e) {
      debugPrint('ID 추출 오류: $path, $e');
      return false;
    }
  }

  /// ✅ 선택된 가구 반환 (한글 키 → 영문 키 변환)
  Map<String, String?> _getSelectedFurniture() {
    return {
      'sofa': selected['소파'],
      'wall': selected['벽'],
      'desk': selected['책상'],
      'floor': selected['바닥'],
      'background': selected['배경'],
    };
  }

  /// ✅ 슬롯 선택 UI
  Widget _buildSlotSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          int slotNum = i + 1;
          bool isActive = slotNum == selectedSlot;
          bool isLocked = slotNum > unlockedSlots;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? Colors.blue
                    : (isLocked ? Colors.grey.shade300 : Colors.grey.shade400),
                foregroundColor: isActive ? Colors.white : Colors.black,
              ),
              onPressed: isLocked
                  ? null
                  : () {
                setState(() {
                  selectedSlot = slotNum;
                  selected = Map<String, String>.from(
                      slotFurniture[slotNum] ?? FurnitureDefaults.defaults);
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocked) const Icon(Icons.lock, size: 16),
                  if (isLocked) const SizedBox(width: 4),
                  Text('슬롯 $slotNum'),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// ✅ Body 빌드
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('가구 정보를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initialize();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        _buildCategoryTabs(),
        _buildFurnitureGrid(),
      ],
    );
  }

  /// ✅ 카테고리 탭
  Widget _buildCategoryTabs() {
    return Container(
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
    );
  }

  /// ✅ 가구 그리드
  Widget _buildFurnitureGrid() {
    List<String> items = furnitureImages[selectedCategory] ?? [];

    return Expanded(
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
          bool unlocked = _isUnlocked(path);

          return _buildFurnitureItem(path, isSelected, unlocked);
        },
      ),
    );
  }

  /// ✅ 가구 아이템
  Widget _buildFurnitureItem(String path, bool isSelected, bool unlocked) {
    return GestureDetector(
      onTap: () async {
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔒 상점에서 구매해야 합니다!'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        setState(() {
          selected[selectedCategory] = path;
          slotFurniture[selectedSlot] = Map<String, String>.from(selected);
        });

        await _saveSlot(selectedSlot);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$selectedCategory 선택됨 (슬롯 $selectedSlot)'),
              duration: const Duration(milliseconds: 800),
            ),
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                width: isSelected ? 3 : 2,
              ),
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
              child: Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
            ),
          if (!unlocked)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, color: Colors.white, size: 40),
                    SizedBox(height: 4),
                    Text(
                      '잠김',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가구 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _getSelectedFurniture());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: unlockNextSlot,
            tooltip: '슬롯 해금 (테스트)',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetToFactory,
            tooltip: '초기화',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSlotSelector(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

}