import 'package:hive_flutter/hive_flutter.dart';

class SettingsBoxKeys {
  static const baseTime = 'baseTime';
  static const extraTime = 'extraTime';
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
}
