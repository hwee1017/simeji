import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive import for persistence
import 'api/store_api.dart';
import 'try_on_page.dart';

const String kBaseCharacterAsset = 'assets/mainchar.png';

/// =======================
/// 오버레이/착의실 정책
/// =======================
const Map<String, bool> kOverlayOnCharacter = {
  '의상': true,
  '헤어': true,
  '얼굴': true,
  '가구': false,
  '테마': false,
  '프로필': false,
};

/// 착의실 페이지에 노출할 카테고리 (순서 유지)
const List<String> kTryOnEnabledCategories = ['의상', '헤어', '얼굴'];

class StorePage extends StatefulWidget {
  final String userId;  // userId 추가
  final String? hair;
  final String? closet;
  final String? face;
  const StorePage({
    super.key,
    required this.userId,
    this.hair,
    this.closet,
    this.face,
  });
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreApi api = InMemoryStoreApi(); // 임시 API 구현 (Hive 연동시 변경 가능)

  String? hair;
  String? closet;
  String? face;
  bool loading = true;
  List<String> categories = [];
  String selectedCategory = '의상';
  int credits = 0;

  final Map<String, List<StoreItem>> _itemsByCat = {};
  StoreItem? trialItem; // (기존 하단 패널과 호환용)

  @override
  void initState() {
    super.initState();
    hair = widget.hair ?? 'assets/hair1.png';
    closet = widget.closet ?? 'assets/closet1.png';
    face = widget.face ?? 'assets/face1.png';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cats = await api.fetchCategories();
    // Hive에서 저장된 보유 코인과 아이템 불러오기
    final coinBox = Hive.box('coins');
    final invBox = Hive.box('inventory');
    final savedCoins = coinBox.get('coin', defaultValue: 0) as int;
    final purchasedIds = List<String>.from(invBox.get('items', defaultValue: []));

    for (final cat in cats) {
      final list = await api.fetchItemsByCategory(cat);
      // Hive에 저장된 purchased 여부를 반영
      final updatedList = list.map((item) {
        if (purchasedIds.contains(item.id)) {
          return item.copyWith(purchased: true);
        }
        return item;
      }).toList();
      _itemsByCat[cat] = updatedList;
    }
    setState(() {
      categories = cats;
      credits = savedCoins;  // "크레딧" 대신 실제 코인 값 사용
      selectedCategory = cats.isNotEmpty ? cats.first : '의상';
      loading = false;
    });
  }

  Future<void> _changeCategory(String cat) async {
    if (selectedCategory == cat) return;
    final list = await api.fetchItemsByCategory(cat);
    // 보유 상태 반영
    final invBox = Hive.box('inventory');
    final purchasedIds = List<String>.from(invBox.get('items', defaultValue: []));
    final updatedList = list.map((item) {
      if (purchasedIds.contains(item.id)) {
        return item.copyWith(purchased: true);
      }
      return item;
    }).toList();
    setState(() {
      selectedCategory = cat;
      _itemsByCat[cat] = updatedList;
    });
  }

  Future<void> _refreshThisCategory() async {
    final list = await api.fetchItemsByCategory(selectedCategory);
    final invBox = Hive.box('inventory');
    final purchasedIds = List<String>.from(invBox.get('items', defaultValue: []));
    setState(() {
      _itemsByCat[selectedCategory] = list.map((item) {
        if (purchasedIds.contains(item.id)) {
          return item.copyWith(purchased: true);
        }
        return item;
      }).toList();
    });
  }

  void _openItemSheet(StoreItem item) {
    final bool overlay = kOverlayOnCharacter[item.category] ?? true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (overlay) Image.asset(kBaseCharacterAsset, height: 180),
                      if (item.imagePath.isNotEmpty)
                        Image.asset(item.imagePath, height: 180),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
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
                    '가격: ${item.price} 코인', // "크레딧"을 "코인"으로 변경
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
            if (!item.purchased)
              ElevatedButton(
                onPressed: () async {
                  final ok = await api.purchase(item.id);
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  if (ok) {
                    // Hive 업데이트: 아이템 구매 상태 저장 및 코인 차감
                    final invBox = Hive.box('inventory');
                    List<String> items =
                    List<String>.from(invBox.get('items', defaultValue: []));
                    if (!items.contains(item.id)) {
                      items.add(item.id);
                      invBox.put('items', items);
                    }
                    final coinBox = Hive.box('coins');
                    final currentCoins =
                    coinBox.get('coin', defaultValue: 0) as int;
                    final newCoins = currentCoins - item.price;
                    coinBox.put('coin', newCoins);
                    final newCredits = newCoins;
                    await _refreshThisCategory();
                    setState(() => credits = newCredits);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매가 완료되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('코인이 부족하거나 구매 불가합니다.')),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = _itemsByCat[selectedCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('상점'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amberAccent,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '보유 코인: $credits', // "크레딧"을 "코인"으로 변경
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 좌측 카테고리(슬라이드) + 하단 'Try on'
                Container(
                  width: 96,
                  color: Colors.grey.shade200,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: categories.length,
                          itemBuilder: (context, i) {
                            final cat = categories[i];
                            final selected = selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => _changeCategory(cat),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.blueAccent
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: selected
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
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // 착의실에는 kTryOnEnabledCategories만 전달
                                final filtered = categories
                                    .where((c) =>
                                    kTryOnEnabledCategories.contains(c))
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TryOnPage(
                                      api: api,
                                      categories: filtered,
                                      initialCategory: filtered.isNotEmpty
                                          ? (filtered.contains(selectedCategory)
                                          ? selectedCategory
                                          : filtered.first)
                                          : '',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.checkroom_rounded),
                              label: const Text('Try on'), // "착의실"을 "Try on"으로 변경
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 우측 2열 카드 그리드
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final overlay = kOverlayOnCharacter[item.category] ?? true;

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openItemSheet(item),
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
                                  // 썸네일
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (overlay)
                                            Image.asset(kBaseCharacterAsset,
                                                height: 110),
                                          if (item.imagePath.isNotEmpty)
                                            Image.asset(item.imagePath,
                                                height: 110),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.price} 코인', // "크레딧"을 "코인"으로 변경
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: item.price > credits
                                          ? Colors.redAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // [구매완료 표시 영역]
                                  SizedBox(
                                    height: 24,
                                    child: item.purchased
                                        ? Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                            color:
                                            Colors.green.shade300),
                                      ),
                                      child: const Text(
                                        '구매완료',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green),
                                      ),
                                    )
                                        : const SizedBox.shrink(),
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
          ),
        ],
      ),
    );
  }
}
