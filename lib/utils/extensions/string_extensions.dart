extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Title case
  String get titleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.capitalize)
        .join(' ');
  }

  // Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  // Check if valid URL
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme &&
          (uri.scheme == 'http' ||
              uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  // Remove extra spaces
  String get clean =>
      trim().replaceAll(RegExp(r'\s+'), ' ');
}