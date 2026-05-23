class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String url;
  final String? imageUrl;
  final String publishedAt;
  final String sourceName;
  final String sourceUrl;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.sourceName,
    required this.sourceUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['image'] as String?,
      publishedAt: json['publishedAt'] as String? ?? '',
      sourceName: json['source']?['name'] as String? ?? '',
      sourceUrl: json['source']?['url'] as String? ?? '',
    );
  }

  // For Hive storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'url': url,
        'image': imageUrl,
        'publishedAt': publishedAt,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
      };

  // Reconstruct from Hive map
  factory NewsArticle.fromCache(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['image'] as String?,
      publishedAt: json['publishedAt'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
    );
  }

  String get timeAgo {
    try {
      final published = DateTime.parse(publishedAt);
      final now = DateTime.now();
      final diff = now.difference(published);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }

  String get readingTime {
    final wordCount = '$title $description'.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }
}