// lib/api/store_api.dart
// Store API interface and in-memory implementation (temporary)
class Item {
  final String id;
  final String category;
  final String name;
  final String description;
  final int price;
  bool purchased;

  Item({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.price,
    this.purchased = false,
  });
}

abstract class StoreApi {
  Future<int> fetchUserCredits();
  Future<List<String>> fetchCategories();
  Future<List<Item>> fetchItems(String category);
  Future<bool> purchaseItem(String itemId);
}

class InMemoryStoreApi implements StoreApi {
  int _userCredits = 150; // initial user credits

  // Predefined categories
  final List<String> _categories = ['의상', '헤어', '얼굴'];

  // Sample items data
  final List<Item> _items = [
    Item(
        id: 'cloth1',
        category: '의상',
        name: '빨간 티셔츠',
        description: '캐릭터가 입을 수 있는 빨간색 티셔츠입니다.',
        price: 100,
        purchased: false),
    Item(
        id: 'cloth2',
        category: '의상',
        name: '파란 바지',
        description: '캐릭터가 입을 수 있는 파란색 바지입니다.',
        price: 120,
        purchased: false),
    Item(
        id: 'hair1',
        category: '헤어',
        name: '기본 헤어',
        description: '캐릭터의 기본 헤어스타일입니다.',
        price: 0,
        purchased: true),  // 이미 보유
    Item(
        id: 'hair2',
        category: '헤어',
        name: '금발 머리',
        description: '화려한 금발 가발입니다.',
        price: 80,
        purchased: false),
    Item(
        id: 'face1',
        category: '얼굴',
        name: '동그란 안경',
        description: '귀여운 동그란 안경입니다.',
        price: 50,
        purchased: false),
    Item(
        id: 'face2',
        category: '얼굴',
        name: '선글라스',
        description: '멋진 선글라스입니다.',
        price: 70,
        purchased: false),
  ];

  @override
  Future<int> fetchUserCredits() async {
    // Returns current user credits
    return _userCredits;
  }

  @override
  Future<List<String>> fetchCategories() async {
    // Returns list of categories
    return _categories;
  }

  @override
  Future<List<Item>> fetchItems(String category) async {
    // Returns items filtered by category
    return _items.where((item) => item.category == category).toList();
  }

  @override
  Future<bool> purchaseItem(String itemId) async {
    // Find the item by id
    try {
      Item item = _items.firstWhere((item) => item.id == itemId);
      if (item.purchased) {
        return false; // already purchased
      }
      if (item.price > _userCredits) {
        return false; // not enough credits
      }
      // Deduct price and mark as purchased
      _userCredits -= item.price;
      item.purchased = true;
      return true;
    } catch (e) {
      // item not found
      return false;
    }
  }
}