import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance =
      HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String newsCache = 'news_cache';

  // BUG 9 fix: open all boxes before runApp
  static Future<void> openAllBoxes() async {
    await Hive.openBox(newsCache);
  }

  Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception(
        'Box $boxName not open.',
      );
    }
    return Hive.box(boxName);
  }

  dynamic read(String key) =>
      getBox(newsCache).get(key);

  Future<void> write(
    String key,
    dynamic value,
  ) async =>
      await getBox(newsCache).put(key, value);

  Future<void> delete(String key) async =>
      await getBox(newsCache).delete(key);

  Future<void> clearNews() async =>
      await getBox(newsCache).clear();
}