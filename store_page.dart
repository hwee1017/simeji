// lib/store_page.dart
import 'package:flutter/material.dart';

/// ===========================================================
/// 1) 데이터 모델 & 임시(In-Memory) API
///    - 실제 DB/서버 준비되면 같은 메서드 시그니처로 교체만 하면 됨
/// ===========================================================

class StoreItem {
  final String id;
  final String category; // '의상' | '헤어' | '얼굴'
  final String name;
  final String description;
  final int price;
  bool purchased; // 구매 여부

  StoreItem({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    this.purchased = false,
  });

  StoreItem copyWith({
    String? id,
    String? category,
    String? name,
    String? description,
    int? price,
    bool? purchased,
  }) {
    return StoreItem(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      purchased: purchased ?? this.purchased,
    );
  }
}

/// API 추상화: UI는 이 인터페이스만 바라봄
abstract class StoreApi {
  Future<int> fetchCredits();
  Future<List<String>> fetchCategories();
  Future<List<StoreItem>> fetchItemsByCategory(String category);
  Future<bool> purchase(String itemId);
}

/// 지금은 실행을 위한 메모리 구현 (앱 재실행 시 초기화됨)
class InMemoryStoreApi implements StoreApi {
  int _credits = 500;
  final List<String> _categories = ['의상', '헤어', '얼굴'];

  final List<StoreItem> _all = [
    // 의상
    StoreItem(
      id: 'cloth1',
      category: '의상',
      name: '스웨터',
      description: '이 스웨터는 푹신하다',
      price: 200,
    ),
    StoreItem(
      id: 'cloth2',
      category: '의상',
      name: '정장',
      description: '깔끔한 정장',
      price: 250,
    ),
    // 헤어
    StoreItem(
      id: 'hair1',
      category: '헤어',
      name: '기본 헤어',
      description: '가장 기본적인 헤어스타일',
      price: 100,
    ),
    StoreItem(
      id: 'hair2',
      category: '헤어',
      name: '세련된 헤어',
      description: '세련된 스타일의 헤어',
      price: 150,
    ),
    // 얼굴
    StoreItem(
      id: 'face1',
      category: '얼굴',
      name: '얼굴 1',
      description: '평범한 얼굴',
      price: 100,
    ),
    StoreItem(
      id: 'face2',
      category: '얼굴',
      name: '얼굴 2',
      description: '개성 있는 얼굴',
      price: 150,
    ),
  ];

  @override
  Future<int> fetchCredits() async => _credits;

  @override
  Future<List<String>> fetchCategories() async => _categories;

  @override
  Future<List<StoreItem>> fetchItemsByCategory(String category) async {
    return _all.where((e) => e.category == category).map((e) => e.copyWith()).toList();
  }

  @override
  Future<bool> purchase(String itemId) async {
    try {
      final idx = _all.indexWhere((e) => e.id == itemId);
      if (idx == -1) return false;
      final item = _all[idx];
      if (item.purchased) return true;
      if (_credits < item.price) return false;
      _credits -= item.price;
      _all[idx] = item.copyWith(purchased: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// ===========================================================
/// 2) 상점 화면 UI
///    - 왼쪽 세로 카테고리
///    - 오른쪽 2열 그리드
///    - 아이템 탭 → 카드형 상세 팝업 (배경 탭 닫힘)
///    - 우상단 크레딧 배지
/// ===========================================================
class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreApi api = InMemoryStoreApi(); // 나중에 Hive/서버 API로 교체
  bool loading = true;

  List<String> categories = [];
  String selectedCategory = '의상';
  int credits = 0;
  final Map<String, List<StoreItem>> _itemsByCat = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cats = await api.fetchCategories();
    final c = await api.fetchCredits();
    // 최초 카테고리 데이터 로드
    for (final cat in cats) {
      _itemsByCat[cat] = await api.fetchItemsByCategory(cat);
    }
    setState(() {
      categories = cats;
      credits = c;
      selectedCategory = cats.isNotEmpty ? cats.first : '의상';
      loading = false;
    });
  }

  Future<void> _changeCategory(String cat) async {
    if (selectedCategory == cat) return;
    // 필요 시 새로고침
    final list = await api.fetchItemsByCategory(cat);
    setState(() {
      selectedCategory = cat;
      _itemsByCat[cat] = list;
    });
  }

  Future<void> _refreshOnlyThisCategory() async {
    final list = await api.fetchItemsByCategory(selectedCategory);
    setState(() {
      _itemsByCat[selectedCategory] = list;
    });
  }

  void _openItemSheet(StoreItem item) {
    showDialog(
      context: context,
      barrierDismissible: true, // 빈 화면 탭 시 닫힘
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이미지 자리(나중에 실제 이미지로 교체 가능)
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Icon(
                    item.category == '의상'
                        ? Icons.checkroom
                        : (item.category == '헤어' ? Icons.face : Icons.emoji_emotions),
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.description),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '가격: ${item.price} 크레딧',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), // 닫기
              child: const Text('닫기'),
            ),
            if (!item.purchased)
              ElevatedButton(
                onPressed: () async {
                  final ok = await api.purchase(item.id);
                  Navigator.pop(ctx); // 우선 닫고
                  if (!mounted) return;
                  if (ok) {
                    final newCredits = await api.fetchCredits();
                    await _refreshOnlyThisCategory();
                    setState(() => credits = newCredits);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매가 완료되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('크레딧이 부족하거나 구매할 수 없습니다.')),
                    );
                  }
                },
                child: const Text('구매'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _itemsByCat[selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('상점'),
        actions: [
          // 보유 크레딧 배지
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '보유 크레딧: $credits',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 왼쪽: 카테고리 세로 분류
          Container(
            width: 96,
            color: Colors.grey.shade200,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                for (final cat in categories)
                  GestureDetector(
                    onTap: () => _changeCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: selectedCategory == cat ? Colors.blueAccent : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selectedCategory == cat
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selectedCategory == cat ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 오른쪽: 아이템 2열 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,       // 2열
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,  // 카드 비율
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openItemSheet(item), // 상세 팝업
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 이미지 자리(회색 박스)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.category == '의상'
                                      ? Icons.checkroom
                                      : (item.category == '헤어' ? Icons.face : Icons.emoji_emotions),
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.price} 크레딧',
                              style: TextStyle(
                                fontSize: 13,
                                color: item.price > credits ? Colors.redAccent : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item.purchased)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Text(
                                  '구매완료',
                                  style: TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
