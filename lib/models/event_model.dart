class EventModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? date;
  final String? time;
  final String? venueName;
  final String? venueCity;
  final String? venueAddress;
  final String? classification;
  final String? priceMin;
  final String? priceMax;
  final String? url;
  final String? status;

  const EventModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.date,
    this.time,
    this.venueName,
    this.venueCity,
    this.venueAddress,
    this.classification,
    this.priceMin,
    this.priceMax,
    this.url,
    this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Get best image
    String? imageUrl;
    final images = json['images'] as List?;
    if (images != null && images.isNotEmpty) {
      // Prefer 16:9 ratio images
      final preferred = images.firstWhere(
        (img) =>
            img['ratio'] == '16_9' &&
            (img['width'] as int? ?? 0) >= 640,
        orElse: () => images.first,
      );
      imageUrl = preferred['url'] as String?;
    }

    // Get venue info
    String? venueName;
    String? venueCity;
    String? venueAddress;
    try {
      final venues =
          json['_embedded']?['venues'] as List?;
      if (venues != null && venues.isNotEmpty) {
        final venue = venues.first;
        venueName = venue['name'] as String?;
        venueCity = venue['city']?['name'] as String?;
        venueAddress = venue['address']?['line1'] as String?;
      }
    } catch (_) {}

    // Get date and time
    String? date;
    String? time;
    try {
      final dates = json['dates'];
      date = dates?['start']?['localDate'] as String?;
      time = dates?['start']?['localTime'] as String?;
      if (time != null && time.length >= 5) {
        // Convert 19:00:00 to 7:00 PM
        final parts = time.split(':');
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        time = '$hour:$minute $period';
      }
    } catch (_) {}

    // Get classification
    String? classification;
    try {
      final classifications =
          json['classifications'] as List?;
      if (classifications != null &&
          classifications.isNotEmpty) {
        classification =
            classifications.first['segment']?['name']
                as String?;
      }
    } catch (_) {}

    // Get price range
    String? priceMin;
    String? priceMax;
    try {
      final priceRanges = json['priceRanges'] as List?;
      if (priceRanges != null && priceRanges.isNotEmpty) {
        priceMin =
            priceRanges.first['min']?.toString();
        priceMax =
            priceRanges.first['max']?.toString();
      }
    } catch (_) {}

    return EventModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Event',
      imageUrl: imageUrl,
      date: date,
      time: time,
      venueName: venueName,
      venueCity: venueCity,
      venueAddress: venueAddress,
      classification: classification,
      priceMin: priceMin,
      priceMax: priceMax,
      url: json['url'] as String?,
      status: json['dates']?['status']?['code']
          as String?,
    );
  }

  // Format date nicely
  String get formattedDate {
    if (date == null) return 'Date TBA';
    try {
      final parts = date!.split('-');
      if (parts.length != 3) return date!;
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final year = parts[0];
      return '${months[month - 1]} $day, $year';
    } catch (_) {
      return date!;
    }
  }

  // Format price range
  String get priceRange {
    if (priceMin == null && priceMax == null) {
      return 'Price TBA';
    }
    if (priceMin == priceMax) return '₹$priceMin';
    return '₹$priceMin - ₹$priceMax';
  }

  // Location string
  String get location {
    final parts = <String>[];
    if (venueName != null) parts.add(venueName!);
    if (venueCity != null) parts.add(venueCity!);
    return parts.join(', ');
  }

  bool get isOnSale => status == 'onsale';
}