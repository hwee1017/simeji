import 'package:hive_flutter/hive_flutter.dart';

class StoreHiveService {
  static const String coinsBoxName = 'coins';
  static const String inventoryBoxName = 'inventory';

  static Box? _coinsBox; // key 'coin' -> int
  static Box? _invBox;   // key 'items' -> List<String>

  static Future<void> init() async {
    // try { await Hive.initFlutter(); } catch (_) {}
    _coinsBox = Hive.isBoxOpen(coinsBoxName)
        ? Hive.box(coinsBoxName)
        : await Hive.openBox(coinsBoxName);
    _invBox = Hive.isBoxOpen(inventoryBoxName)
        ? Hive.box(inventoryBoxName)
        : await Hive.openBox(inventoryBoxName);
  }

  /// 비어있으면만 기본 세팅(보존형)
  static Future<void> seedDefaultsIfEmpty() async {
    final coins = _coinsBox ?? Hive.box(coinsBoxName);
    final inv   = _invBox ?? Hive.box(inventoryBoxName);

    final currentCoin = (coins.get('coin') as int?) ?? 10000;
    await coins.put('coin', currentCoin);

    final defaults = <String>['cloth1','face1','face2','hair1'];
    final current  = List<String>.from((inv.get('items') as List?) ?? const <String>[]);
    bool changed = false;
    for (final id in defaults) {
      if (!current.contains(id)) { current.add(id); changed = true; }
    }
    if (changed) await inv.put('items', current);
  }

  /// 공장초기화(덮어쓰기형)
  static Future<void> resetToFactory() async {
    final coins = Hive.isBoxOpen(coinsBoxName)
        ? Hive.box(coinsBoxName)
        : await Hive.openBox(coinsBoxName);
    final inv = Hive.isBoxOpen(inventoryBoxName)
        ? Hive.box(inventoryBoxName)
        : await Hive.openBox(inventoryBoxName);

    await coins.clear();
    await inv.clear();
    await coins.put('coin', 1000);
    await inv.put('items', <String>['cloth1','face1','face2','hair1']);
  }

  // 코인
  static int getCoins() {
    final coins = _coinsBox ?? Hive.box(coinsBoxName);
    return (coins.get('coin') as int?) ?? 0;
  }
  static Future<void> setCoins(int v) async {
    final coins = _coinsBox ?? Hive.box(coinsBoxName);
    await coins.put('coin', v);
  }
  static Future<void> addCoins(int delta) async => setCoins(getCoins() + delta);

  // 인벤토리
  static List<String> getPurchasedIds() {
    final inv = _invBox ?? Hive.box(inventoryBoxName);
    final raw = (inv.get('items') as List?) ?? const <String>[];
    return List<String>.from(raw);
  }
  static Future<void> addPurchased(String itemId) async {
    final inv = _invBox ?? Hive.box(inventoryBoxName);
    final cur = getPurchasedIds();
    if (!cur.contains(itemId)) { cur.add(itemId); await inv.put('items', cur); }
  }
  static bool isPurchased(String itemId) => getPurchasedIds().contains(itemId);

  // 서버 페이로드 (참고)
  static Map<String, dynamic> buildInventoryPayload(String userId) => {
    'user_id': userId, 'items': getPurchasedIds(), 'coin': getCoins(),
  };
  static Map<String, dynamic> buildPurchasePayload({
    required String userId, required String itemId, required int price, DateTime? time,
  }) => {
    'user_id': userId, 'item_id': itemId, 'price': price,
    'time': (time ?? DateTime.now()).toIso8601String(),
  };
}
