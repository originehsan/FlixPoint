import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCinemaData() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('cinema');

  final cinemas = [
    {
      'name': 'PVR Cinemas - Shipra Mall',
      'address': 'Shipra Mall, Indirapuram, Ghaziabad',
      'city': 'Ghaziabad',
      'distance': '1.2',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'INOX - Gaur City Mall',
      'address': 'Gaur City Mall, Greater Noida West',
      'city': 'Greater Noida',
      'distance': '4.2',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/4/4d/Inox_Leisure_logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'Cinepolis - Ansal Plaza',
      'address': 'Ansal Plaza, Vaishali, Ghaziabad',
      'city': 'Ghaziabad',
      'distance': '2.8',
      'logo':
          'https://upload.wikimedia.org/wikipedia/commons/8/8e/Cinepolis_logo.svg',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'PVR Cinemas - Crossings Republik',
      'address': 'Crossings Republik Mall, Ghaziabad',
      'city': 'Ghaziabad',
      'distance': '3.5',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'Wave Cinemas - Kaushambi',
      'address': 'Wave Mall, Kaushambi, Ghaziabad',
      'city': 'Ghaziabad',
      'distance': '2.1',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'PVR Cinemas - Spice World Mall',
      'address': 'Spice World Mall, Sector 25A, Noida',
      'city': 'Noida',
      'distance': '5.5',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'INOX - Logix City Centre',
      'address': 'Logix City Centre, Sector 32, Noida',
      'city': 'Noida',
      'distance': '6.2',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/4/4d/Inox_Leisure_logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'Cinepolis - DLF Mall of India',
      'address': 'DLF Mall of India, Sector 18, Noida',
      'city': 'Noida',
      'distance': '7.1',
      'logo':
          'https://upload.wikimedia.org/wikipedia/commons/8/8e/Cinepolis_logo.svg',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'PVR - Ambience Mall',
      'address': 'Ambience Mall, Vasundhara, Ghaziabad',
      'city': 'Ghaziabad',
      'distance': '3.8',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
    {
      'name': 'Carnival Cinemas - Pacific Mall',
      'address': 'Pacific Mall, Tagore Garden, Delhi',
      'city': 'Delhi',
      'distance': '12.5',
      'logo':
          'https://upload.wikimedia.org/wikipedia/en/9/9f/PVR_Cinemas_Logo.png',
      'showTimings': ['10:00 AM', '1:00 PM', '4:00 PM', '7:00 PM', '10:00 PM'],
    },
  ];

  for (final cinema in cinemas) {
    await collection.add(cinema);
  }

  print('Cinema data seeded successfully!');
}
