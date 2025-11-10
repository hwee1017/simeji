import 'package:hive_flutter/hive_flutter.dart';

class SettingsBoxKeys {
  static const baseTime = 'baseTime';
  static const extraTime = 'extraTime';
  static const userName = 'userName'; 
  static const userId = 'userId';  
}

class UserHiveService {
  static late Box settingsBox;

  static Future<void> init() async {
    settingsBox = await Hive.openBox('settingsBox');
  }

  static int getBaseTime() {
    return settingsBox.get(SettingsBoxKeys.baseTime, defaultValue: 5);
  }

  static int getExtraTime() {
    return settingsBox.get(SettingsBoxKeys.extraTime, defaultValue: 4);
  }

  static Future<void> saveSettings({
    required int baseTime,
    required int extraTime,
  }) async {
    await settingsBox.put(SettingsBoxKeys.baseTime, baseTime);
    await settingsBox.put(SettingsBoxKeys.extraTime, extraTime);
  }

  // ===== 유저 정보 관련 =====
  static String? getUserName() {
    return settingsBox.get(SettingsBoxKeys.userName);
  }

  static String? getUserId() {
    return settingsBox.get(SettingsBoxKeys.userId);
  }

  static Future<void> saveUserInfo({
    required String? userName,
    required String? userId,
  }) async {
    await settingsBox.put(SettingsBoxKeys.userName, userName);
    await settingsBox.put(SettingsBoxKeys.userId, userId);
  }

  static Future<void> clearUserInfo() async {
    await settingsBox.delete(SettingsBoxKeys.userName);
    await settingsBox.delete(SettingsBoxKeys.userId);
  }
}
