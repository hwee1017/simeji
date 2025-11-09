import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'store_hive_service.dart';

/// 가구 기본값 상수
class FurnitureDefaults {
  static const Map<String, String> defaults = {
    '소파': 'assets/sofa1.png',
    '벽': 'assets/wall1.png',
    '책상': 'assets/desk1.png',
    '바닥': 'assets/floor.png',
    '배경': 'assets/background1.png',
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

  late Map<String, String> selected;

  final Map<String, List<String>> furnitureImages = {
    '소파': ['assets/sofa1.png', 'assets/sofa2.png'],
    '벽': ['assets/wall1.png', 'assets/wall2.png'],
    '책상': ['assets/desk1.png', 'assets/desk2.png'],
    '바닥': ['assets/floor.png', 'assets/floor2.png'],
    '배경': ['assets/background1.png', 'assets/background2.png'],
  };

  // ✅ 구매한 가구 목록
  List<String> purchasedIds = [];

  // ✅ 로딩 상태
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// ✅ 초기화 (비동기 처리)
  Future<void> _initialize() async {
    // 선택된 가구 초기화
    selected = {
      '소파': widget.selectedFurniture?['sofa'] ?? FurnitureDefaults.defaults['소파']!,
      '벽': widget.selectedFurniture?['wall'] ?? FurnitureDefaults.defaults['벽']!,
      '책상': widget.selectedFurniture?['desk'] ?? FurnitureDefaults.defaults['책상']!,
      '바닥': widget.selectedFurniture?['floor'] ?? FurnitureDefaults.defaults['바닥']!,
      '배경': widget.selectedFurniture?['background'] ?? FurnitureDefaults.defaults['배경']!,
    };

    // 가구 데이터 로드
    await _loadPurchasedFurniture();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ Hive에서 가구 정보 불러오기 (에러 처리 추가)
  Future<void> _loadPurchasedFurniture() async {
    try {
      await StoreHiveService.init();
      await StoreHiveService.seedDefaultsIfEmpty();

      if (mounted) {
        setState(() {
          purchasedIds = StoreHiveService.getPurchasedIds();
        });
      }
    } catch (e) {
      debugPrint('가구 데이터 로딩 실패: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '가구 정보를 불러오는데 실패했습니다.';
        });
      }
    }
  }

  /// ✅ 구매 여부 확인 함수 (개선)
  bool _isUnlocked(String path) {
    try {
      final filename = path.split('/').last; // assets/sofa2.png → sofa2.png
      final id = filename.split('.').first;  // sofa2.png → sofa2

      // 1번 가구는 기본 해금
      if (id.endsWith('1')) return true;

      return purchasedIds.contains(id);
    } catch (e) {
      debugPrint('ID 추출 오류: $path, $e');
      return false; // 오류 시 잠금 처리
    }
  }

  /// ✅ 선택된 가구 데이터 반환
  Map<String, String?> _getSelectedFurniture() {
    return {
      'sofa': selected['소파'],
      'wall': selected['벽'],
      'desk': selected['책상'],
      'floor': selected['바닥'],
      'background': selected['배경'],
    };
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
      ),
      body: _buildBody(),
    );
  }

  /// ✅ Body 빌드 (로딩/에러 상태 처리)
  Widget _buildBody() {
    // 로딩 중
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

    // 에러 발생
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
                _loadPurchasedFurniture();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 정상 화면
    return Row(
      children: [
        _buildCategoryTabs(),
        _buildFurnitureGrid(),
      ],
    );
  }

  /// ✅ 세로 탭 빌드
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

  /// ✅ 가구 그리드 빌드
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

  /// ✅ 가구 아이템 빌드
  Widget _buildFurnitureItem(String path, bool isSelected, bool unlocked) {
    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          // 잠긴 가구 탭 시 알림
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔒 상점에서 구매해야 합니다!'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // 가구 선택
        setState(() {
          selected[selectedCategory] = path;
        });

        // 선택 피드백
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$selectedCategory 선택됨!'),
            duration: const Duration(milliseconds: 800),
          ),
        );
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

          // 선택 표시
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
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

          // 잠금 표시
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
}