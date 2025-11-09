import 'package:flutter/material.dart';
import 'api/store_api.dart';
import 'services/store_hive_service.dart';
import 'try_on_page.dart';

const String kBaseCharacterAsset = 'assets/mainchar.png';

/// 캐릭터 위 오버레이 정책
const Map<String, bool> kOverlayOnCharacter = {
  '의상': true,
  '헤어': true,
  // '얼굴'은 UI에서 제거
  '가구': false,
  '테마': false,
  '프로필': false,
};

/// Try on 허용 카테고리 — '얼굴' 제외
const List<String> kTryOnEnabledCategories = ['의상', '헤어'];

class StorePage extends StatefulWidget {
  final String userId;
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
  final StoreApi api = InMemoryStoreApi();

  String? hair;
  String? closet;
  String? face;

  bool loading = true;
  List<String> categories = [];
  String selectedCategory = '의상';

  int coins = StoreHiveService.getCoins(); // CHANGED: 첫 렌더부터 Hive 값

  final Map<String, List<StoreItem>> _itemsByCat = {};

  @override
  void initState() {
    super.initState();
    hair = widget.hair ?? 'assets/hair1.png';
    closet = widget.closet ?? 'assets/closet1.png';
    face = widget.face ?? 'assets/face1.png';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final rawCats = await api.fetchCategories();
    final cats = rawCats.where((c) => c != '얼굴').toList(growable: false); // CHANGED: '얼굴' 제거

    final purchasedIds = StoreHiveService.getPurchasedIds();
    final savedCoins = await api.fetchCredits();

    for (final cat in cats) {
      final list = await api.fetchItemsByCategory(cat);
      _itemsByCat[cat] = list
          .map((it) =>
      purchasedIds.contains(it.id) ? it.copyWith(purchased: true) : it)
          .toList();
    }

    setState(() {
      categories = cats;
      coins = savedCoins;
      selectedCategory = cats.isNotEmpty ? cats.first : '의상';
      loading = false;
    });
  }

  Future<void> _changeCategory(String cat) async {
    if (selectedCategory == cat) return;
    final list = await api.fetchItemsByCategory(cat);
    final purchased = StoreHiveService.getPurchasedIds();
    setState(() {
      selectedCategory = cat;
      _itemsByCat[cat] = list
          .map((it) =>
      purchased.contains(it.id) ? it.copyWith(purchased: true) : it)
          .toList();
    });
  }

  Future<void> _refreshThisCategory() async {
    final list = await api.fetchItemsByCategory(selectedCategory);
    final purchased = StoreHiveService.getPurchasedIds();
    setState(() {
      _itemsByCat[selectedCategory] = list
          .map((it) =>
      purchased.contains(it.id) ? it.copyWith(purchased: true) : it)
          .toList();
    });
  }

  Future<void> _syncCoins() async {
    final latest = await api.fetchCredits();
    if (!mounted) return;
    setState(() => coins = latest);
  }

  void _openItemSheet(StoreItem item) {
    final bool overlay = kOverlayOnCharacter[item.category] ?? true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text(item.description)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '가격: ${item.price} 코인',
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
          // CHANGED: 버튼 순서 교체 — [구매] → [닫기]
          if (!item.purchased)
            ElevatedButton(
              onPressed: () async {
                final ok = await api.purchase(item.id); // CHANGED: 차감은 여기서 X, API만 호출
                Navigator.pop(ctx);
                if (!mounted) return;

                if (ok) {
                  await _refreshThisCategory();
                  await _syncCoins(); // Hive 최신값 재로딩
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
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
                )
              ],
            ),
            child: Text(
              '보유 코인: $coins',
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
                // 좌측 카테고리 + Try on
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
                                      color:
                                      Colors.black.withOpacity(0.08),
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
                          padding:
                          const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
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
                              label: const Text('Try on'),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 우측 상품 그리드
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
                        final overlay =
                        (kOverlayOnCharacter[item.category] ?? true);

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _openItemSheet(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                              Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (overlay)
                                            Image.asset(
                                              kBaseCharacterAsset,
                                              height: 110,
                                            ),
                                          if (item.imagePath.isNotEmpty)
                                            Image.asset(
                                              item.imagePath,
                                              height: 110,
                                            ),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.price} 코인',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: item.price > coins
                                          ? Colors.redAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 24,
                                    child: item.purchased
                                        ? Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                        Colors.green.shade50,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors
                                                .green.shade300),
                                      ),
                                      child: const Text(
                                        '구매완료',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                        ),
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
