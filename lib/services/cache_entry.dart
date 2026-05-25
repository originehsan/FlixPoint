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