import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/store_hive_service.dart';

@immutable
class StoreItem {
  final String id;
  final String category;
  final String name;
  final String description;
  final int price;
  final bool purchased;
  final String imagePath;

  const StoreItem({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    this.purchased = false,
    this.imagePath = '',
  });

  StoreItem copyWith({
    String? id,
    String? category,
    String? name,
    String? description,
    int? price,
    bool? purchased,
    String? imagePath,
  }) {
    return StoreItem(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      purchased: purchased ?? this.purchased,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

abstract class StoreApi {
  Future<int> fetchCredits();
  Future<List<String>> fetchCategories();
  Future<List<StoreItem>> fetchItemsByCategory(String category);
  Future<bool> purchase(String itemId);
}

/// 최소 수정: 코인/구매 처리는 여기서 **한 번만**
class InMemoryStoreApi implements StoreApi {
  int _credits = StoreHiveService.getCoins(); // CHANGED: Hive 값으로 초기화

  final Map<String, List<StoreItem>> _itemsByCategory = {
    '의상': [
      StoreItem(
        id: 'cloth1',
        category: '의상',
        name: '부드러운 스웨터',
        description: '푹신푸근한 스웨터. 구름을 입고 있는 듯한 느낌이다.',
        price: 250,
        imagePath: 'assets/closet1.png',
      ),
      StoreItem(
        id: 'cloth2',
        category: '의상',
        name: '세련된 셔츠',
        description: '아주 세련된 셔츠. 입고 있으면 자신감을 얻는다.',
        price: 250,
        imagePath: 'assets/closet2.png',
      ),
    ],
    '헤어': [
      StoreItem(
        id: 'hair1',
        category: '헤어',
        name: '단발 머리',
        description: '자연스러운 헤어컬의 단발머리',
        price: 100,
        imagePath: 'assets/hair1.png',
      ),
      StoreItem(
        id: 'hair2',
        category: '헤어',
        name: '세련된 머리',
        description: '세련된 스타일의 머리스타일',
        price: 150,
        imagePath: 'assets/hair2.png',
      ),
    ],
    // 얼굴 카테고리는 유지(데이터 보존) — UI에서만 숨긴다.
    '얼굴': [
      StoreItem(
        id: 'face1',
        category: '얼굴',
        name: '얼굴 1',
        description: '둥글둥글한 인상의 얼굴',
        price: 150,
        imagePath: 'assets/face1.png',
      ),
      StoreItem(
        id: 'face2',
        category: '얼굴',
        name: '얼굴 2',
        description: '개성 있는 얼굴',
        price: 150,
        imagePath: 'assets/face2.png',
      ),
    ],
    '가구': [
      StoreItem(id: 'desk1', category: '가구', name: '책상', description: '편한 책상', price: 300, purchased: true, imagePath: 'assets/desk1.png'),
      StoreItem(id: 'desk2', category: '가구', name: 'TV서랍장', description: '지지직, 드르륵', price: 450, imagePath: 'assets/desk2.png'),
      StoreItem(id: 'sofa1', category: '가구', name: '핑크 소파', description: '마치 바닥에 앉아 등받이로 써야할 것만 같다.', price: 300, imagePath: 'assets/sofa1.png'),
      StoreItem(id: 'sofa2', category: '가구', name: '곰인형 소파', description: '너무 귀여워. 너무 포근해. 마치 아기 같아.', price: 20000, imagePath: 'assets/sofa2.png'),
      StoreItem(id: 'wall1', category: '가구', name: '액자', description: '액자', price: 20000, imagePath: 'assets/wall1.png'),
      StoreItem(id: 'wall2', category: '가구', name: '창문', description: '1+1+ㅡ+ㅡ=?', price: 20000, imagePath: 'assets/wall2.png'),
    ],
    '테마': [
      StoreItem(id: 'background1', category: '테마', name: '갈색 배경', description: '갈색', price: 500, imagePath: 'assets/background1.png'),
      StoreItem(id: 'background2', category: '테마', name: '핑크 줄무늬 배경', description: '핑크 , 줄무늬', price: 650, imagePath: 'assets/background2.png'),
      StoreItem(id: 'floor1', category: '테마', name: '갈색 바닥', description: '갈색', price: 500, imagePath: 'assets/floor.png'),
      StoreItem(id: 'floor2', category: '테마', name: '핑크 줄무늬 바닥', description: '핑크 , 줄무늬', price: 650, imagePath: 'assets/floor2.png'),
    ],
    '프로필': [
      StoreItem(
        id: 'profile1',
        category: '프로필',
        name: '여자',
        description: 'ENFP 여자',
        price: 200,
        imagePath: 'assets/profile1.png',
      ),
      StoreItem(
        id: 'profile2',
        category: '프로필',
        name: '남자',
        description: 'ISTJ 남자',
        price: 200,
        imagePath: 'assets/profile2.png',
      ),
    ],
  };

  @override
  Future<int> fetchCredits() async {
    _credits = StoreHiveService.getCoins(); // CHANGED: 항상 Hive와 동기화
    return _credits;
  }

  @override
  Future<List<String>> fetchCategories() async =>
      _itemsByCategory.keys.toList(growable: false);

  @override
  Future<List<StoreItem>> fetchItemsByCategory(String category) async =>
      List<StoreItem>.from(_itemsByCategory[category] ?? const <StoreItem>[]);

  @override
  Future<bool> purchase(String itemId) async {
    // 여기서만 차감/구매 처리 → 중복 차감 방지
    for (final list in _itemsByCategory.values) {
      final idx = list.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        final it = list[idx];
        if (it.purchased) return true;

        final currentCoins = StoreHiveService.getCoins();
        if (currentCoins < it.price) return false;

        final newCoins = currentCoins - it.price;        // 차감
        await StoreHiveService.setCoins(newCoins);        // Hive 반영
        _credits = newCoins;                              // 내부 캐시 반영
        list[idx] = it.copyWith(purchased: true);        // 아이템 구매 처리
        await StoreHiveService.addPurchased(it.id);       // 인벤토리 반영
        return true;
      }
    }
    return false;
  }
}

/// (필요시) 서버 API용 클래스는 기존 그대로 유지 가능
class HttpStoreApi implements StoreApi {
  final String userId;
  HttpStoreApi(this.userId);
  final String baseUrl = 'https://api.example.com';

  @override
  Future<int> fetchCredits() async {
    final url = Uri.parse('$baseUrl/$userId/credits');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['credits'] as int;
    }
    return StoreHiveService.getCoins();
  }

  @override
  Future<List<String>> fetchCategories() async {
    final url = Uri.parse('$baseUrl/$userId/categories');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  Future<List<StoreItem>> fetchItemsByCategory(String category) async {
    final url = Uri.parse('$baseUrl/$userId/inventory?category=$category');
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List;
      return data.map((e) => StoreItem(
        id: e['id'],
        category: e['category'],
        name: e['name'],
        description: e['description'],
        price: e['price'],
        purchased: e['purchased'],
        imagePath: e['imagePath'],
      )).toList();
    }
    return [];
  }

  @override
  Future<bool> purchase(String itemId) async {
    final url = Uri.parse('$baseUrl/$userId/purchase');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'item_id': itemId,
        'time': DateTime.now().toIso8601String(),
      }),
    );
    return resp.statusCode == 200;
  }
}
