
class CacheEntry {
  final dynamic data;
  final DateTime cachedAt;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    this.duration = const Duration(minutes: 30),
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > duration;
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry> _cache = {};

  void set(
    String key,
    dynamic data, {
    Duration duration = const Duration(minutes: 30),
  }) {
    _cache[key] = CacheEntry(
      data: data,
      cachedAt: DateTime.now(),
      duration: duration,
    );
  }

  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  void remove(String key) => _cache.remove(key);

  void clear() => _cache.clear();

  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired);
  }
}