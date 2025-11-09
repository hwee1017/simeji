// lib/api/store_api.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// 모델: StoreItem
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

/// 과거 별칭 호환
typedef Item = StoreItem;

/// API 인터페이스
abstract class StoreApi {
  Future<int> fetchCredits();
  Future<List<String>> fetchCategories();
  Future<List<StoreItem>> fetchItemsByCategory(String category);
  Future<bool> purchase(String itemId);
}

/// 메모리 구현 (기존 그대로)
class InMemoryStoreApi implements StoreApi {
  int _credits = 0;

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
      StoreItem(id: 'keke', category: '얼굴', name: '케케', description: '케케케케케', price: 150, imagePath: 'assets/keke.png'),
      StoreItem(id: 'love', category: '얼굴', name: '하트 눈', description: '세계는 사랑에 빠져있는거야. 너를 생각하면 나는 떨려와.', price: 150, imagePath: 'assets/love.png'),
      StoreItem(id: 'sad', category: '얼굴', name: '울고 있는 얼굴', description: '내 골반이 멈추지 않는 탓일까 ㅜ.ㅜ', price: 150, imagePath: 'assets/sad.png'),
      StoreItem(id: 'angry', category: '얼굴', name: '화난 얼굴', description: '나 화났다.', price: 150, imagePath: 'assets/angry.png'),
      StoreItem(id: 'annoying', category: '얼굴', name: '짜증난 얼굴', description: '아 짜증나!!', price: 150, imagePath: 'assets/annoying.png'),
      StoreItem(id: 'happy', category: '얼굴', name: '행복한 얼굴', description: '세상만사 다 기쁘게 받아들일 준비 되셨나요?', price: 150, imagePath: 'assets/happy.png'),
      StoreItem(id: 'yum', category: '얼굴', name: '욤', description: '욤 owo', price: 150, imagePath: 'assets/yum.png'),
      StoreItem(id: 'surprise', category: '얼굴', name: '놀란 얼굴', description: '아 깜놀했네!', price: 150, imagePath: 'assets/surprise.png'),
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
      StoreItem(id: 'profile1', category: '프로필', name: '여자', description: 'ENFP 여자', price: 200, imagePath: 'assets/profile1.png'),
      StoreItem(id: 'profile2', category: '프로필', name: '남자', description: 'ISTJ 남자', price: 200, imagePath: 'assets/profile2.png'),
    ],
  };

  @override
  Future<int> fetchCredits() async => _credits;

  @override
  Future<List<String>> fetchCategories() async =>
      _itemsByCategory.keys.toList(growable: false);

  @override
  Future<List<StoreItem>> fetchItemsByCategory(String category) async =>
      List<StoreItem>.from(_itemsByCategory[category] ?? const <StoreItem>[]);

  @override
  Future<bool> purchase(String itemId) async {
    for (final list in _itemsByCategory.values) {
      final idx = list.indexWhere((e) => e.id == itemId);
      if (idx != -1) {
        final it = list[idx];
        if (it.purchased) return true;         // 이미 구매됨
        if (_credits < it.price) return false; // 코인 부족
        _credits -= it.price;
        list[idx] = it.copyWith(purchased: true);
        return true;
      }
    }
    return false; // 아이템 없음
  }
}

/// 서버 연동 예시 (userId 기반) — 그대로 유지
class HttpStoreApi implements StoreApi {
  final String userId;
  HttpStoreApi(this.userId);

  final String baseUrl = 'https://api.example.com';

  @override
  Future<int> fetchCredits() async {
    final url = Uri.parse('$baseUrl/$userId/credits');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['credits'] as int;
    }
    return 0;
  }

  @override
  Future<List<String>> fetchCategories() async {
    final url = Uri.parse('$baseUrl/$userId/categories');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => e.toString()).toList();
    }
    return InMemoryStoreApi().fetchCategories();
  }

  @override
  Future<List<StoreItem>> fetchItemsByCategory(String category) async {
    final url = Uri.parse('$baseUrl/$userId/inventory');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((e) => StoreItem(
        id: e['id'],
        category: e['category'],
        name: e['name'],
        description: e['description'],
        price: e['price'],
        purchased: e['purchased'],
        imagePath: e['imagePath'],
      ))
          .toList();
    }
    return [];
  }

  @override
  Future<bool> purchase(String itemId) async {
    final url = Uri.parse('$baseUrl/$userId/purchase');
    final purchaseTime = DateTime.now().toIso8601String();
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'item_id': itemId,
        // 'price': price, // 필요 시 포함
        'time': purchaseTime,
      }),
    );
    return response.statusCode == 200;
  }
}

/// ====== 여기부터가 딱! 수정 포인트 ======
/// 인벤토리 업로드는 GET에 body가 아니라, 표준대로 JSON 바디를 가진 POST/PUT을 사용.
Future<void> uploadInventory(String userId) async {
  final invBox = Hive.box('inventory');
  final items = List<String>.from(invBox.get('items', defaultValue: []));
  final url = Uri.parse('https://api.example.com/$userId/inventory');

  await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'items': items}),
  );
}

/// 구매 정보 업로드 (기존 그대로 POST)
Future<void> uploadPurchase(
    String userId,
    String itemId,
    int price,
    DateTime time,
    ) async {
  final url = Uri.parse('https://api.example.com/$userId/purchase');
  await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user_id': userId,
      'item_id': itemId,
      'price': price,
      'time': time.toIso8601String(),
    }),
  );
}
