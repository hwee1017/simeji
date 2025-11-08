import 'package:flutter/material.dart';
import 'api/store_api.dart';
import 'try_on_page.dart';

const String kBaseCharacterAsset = 'assets/mainchar.png';

/// =======================
/// 오버레이/착의실 정책 (여기만 바꾸면 전체 반영)
/// =======================

/// 캐릭터 위에 덮씌워서 미리보기를 보여줄 카테고리
/// true  → 캐릭터 + 아이템(오버레이)
/// false → 아이템만 단독 표시 (인테리어/가구/프로필 등)
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
  const StorePage({super.key});
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreApi api = InMemoryStoreApi();

  bool loading = true;
  List<String> categories = [];
  String selectedCategory = '의상';
  int credits = 0;

  final Map<String, List<StoreItem>> _itemsByCat = {};
  StoreItem? trialItem; // (기존 하단 패널과 호환용)

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final cats = await api.fetchCategories();
    final c = await api.fetchCredits();
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
    final list = await api.fetchItemsByCategory(cat);
    setState(() {
      selectedCategory = cat;
      _itemsByCat[cat] = list;
    });
  }

  Future<void> _refreshThisCategory() async {
    final list = await api.fetchItemsByCategory(selectedCategory);
    setState(() {
      _itemsByCat[selectedCategory] = list;
    });
  }

  void _openItemSheet(StoreItem item) {
    final bool overlay = kOverlayOnCharacter[item.category] ?? true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
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
                    final newCredits = await api.fetchCredits();
                    await _refreshThisCategory();
                    setState(() => credits = newCredits);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구매가 완료되었습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('크레딧이 부족하거나 구매 불가합니다.')),
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
            child: Text('보유 크레딧: $credits',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 좌측 카테고리(슬라이드) + 하단 '착의실'
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
                                      color: selected ? Colors.white : Colors.black87,
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
                              label: const Text('착의실'),
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
                                    '${item.price} 크레딧',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: item.price > credits
                                          ? Colors.redAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // [FIX] 구매완료 표시 영역 고정 (상자 줄어드는 버그 해결)
                                  SizedBox(
                                    height: 24,
                                    child: item.purchased
                                        ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade300),
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
