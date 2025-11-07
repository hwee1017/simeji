import 'package:flutter/material.dart';
import 'api/store_api.dart';

const String kBaseCharacterAsset = 'assets/mainchar.png';

/// 착의실에서 카테고리별로 캐릭터 모델 사용 여부 지정
/// (store_page.dart 의 kOverlayOnCharacter 와 동일 정책을 사용하면 UX 일관)
const Map<String, bool> kCategoryUsesModel = {
  '의상': true,
  '헤어': true,
  '얼굴': true,
  // 착의실에서는 기본적으로 아래 카테고리는 안 보이지만
  // 혹시 보이게 바꾸고 싶을 때 false로 두면 캐릭터 없이 노출
  '가구': false,
  '인테리어': false,
  '프로필': false,
};

class TryOnPage extends StatefulWidget {
  final StoreApi api;
  final List<String> categories;     // 이미 필터된 카테고리(의상/헤어/얼굴) 전달됨
  final String initialCategory;

  const TryOnPage({
    super.key,
    required this.api,
    required this.categories,
    required this.initialCategory,
  });

  @override
  State<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends State<TryOnPage> {
  late String selectedCategory;
  final Map<String, List<StoreItem>> _itemsByCat = {};
  final Map<String, StoreItem?> _selectedByCategory = {};

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // widget.categories 는 이미 (의상/헤어/얼굴)로 필터되어 넘어옴
    for (final cat in widget.categories) {
      final items = await widget.api.fetchItemsByCategory(cat);
      _itemsByCat[cat] = items;
      _selectedByCategory[cat] = null;
    }
    setState(() {});
  }

  void _selectCategory(String cat) {
    if (selectedCategory == cat) return;
    setState(() => selectedCategory = cat);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsByCat[selectedCategory] ?? const <StoreItem>[];

    // model=true인 카테고리에서 선택이 하나라도 있으면 캐릭터 표시
    final bool showModel = widget.categories.any(
          (cat) => (kCategoryUsesModel[cat] ?? true) &&
          _selectedByCategory[cat] != null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('착의실')),
      body: Column(
        children: [
          // 상단 큰 미리보기
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (showModel) Image.asset(kBaseCharacterAsset, height: 260),
                    // model=true : 캐릭터 위에 오버레이
                    for (final cat in widget.categories)
                      if ((kCategoryUsesModel[cat] ?? true) &&
                          _selectedByCategory[cat]?.imagePath.isNotEmpty == true)
                        Image.asset(_selectedByCategory[cat]!.imagePath,
                            height: 260),
                    // model=false : 캐릭터 없이 단독(필요 시 Positioned로 배치 커스텀)
                    for (final cat in widget.categories)
                      if (!(kCategoryUsesModel[cat] ?? true) &&
                          _selectedByCategory[cat]?.imagePath.isNotEmpty == true)
                        Image.asset(_selectedByCategory[cat]!.imagePath,
                            height: 260),
                  ],
                ),
              ),
            ),
          ),

          // 하단: 좌 카테고리 / 우 아이템 그리드
          Expanded(
            child: Row(
              children: [
                // 왼쪽 카테고리
                Container(
                  width: 96,
                  color: Colors.grey.shade200,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.categories.length,
                    itemBuilder: (context, i) {
                      final cat = widget.categories[i];
                      final selected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => _selectCategory(cat),
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

                // 오른쪽: 아이템 그리드
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
                        final selected =
                            _selectedByCategory[selectedCategory]?.id ==
                                item.id;
                        final bool usesModel =
                            kCategoryUsesModel[selectedCategory] ?? true;

                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedByCategory[selectedCategory] = null;
                              } else {
                                _selectedByCategory[selectedCategory] = item;
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? Colors.blue.shade50 : Colors.white,
                              border: Border.all(
                                color: selected
                                    ? Colors.blueAccent
                                    : Colors.grey.shade400,
                              ),
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
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (usesModel)
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
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${item.price} 크레딧',
                                      style: const TextStyle(fontSize: 12)),
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

          // 하단 액션
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (final k in _selectedByCategory.keys) {
                            _selectedByCategory[k] = null;
                          }
                        });
                      },
                      child: const Text('모두 해제'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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