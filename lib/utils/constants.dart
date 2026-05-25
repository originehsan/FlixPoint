import 'package:flutter_dotenv/flutter_dotenv.dart';

// TMDB API
final String tmdbApiKey = dotenv.env['TMDB_API_KEY'] ?? '';
final String tmdbBaseUrl = dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3';
final String tmdbImageBase = dotenv.env['TMDB_IMAGE_BASE'] ?? 'https://image.tmdb.org/t/p/w500';
final String tmdbImageOriginal = dotenv.env['TMDB_IMAGE_ORIGINAL'] ?? 'https://image.tmdb.org/t/p/original';

// GNews API
final String gNewsApiKey = dotenv.env['GNEWS_API_KEY'] ?? '';
final String gNewsBaseUrl = dotenv.env['GNEWS_BASE_URL'] ?? 'https://gnews.io/api/v4';

// UPI
final String upiId = dotenv.env['UPI_ID'] ?? '';
final String upiName = dotenv.env['UPI_NAME'] ?? 'FlixPoint';

// Seat Prices
const int seatPriceClassic = 1;
const int seatPricePremium = 2;
const int seatPriceVip = 3;

// Seat Lock Duration
const int seatLockMinutes = 2;

// Shared Preferences Keys
const String keyName = 'name';
const String keyOnboarding = 'onboarding_done';

// Firestore Collections
const String colUsers = 'Users';
const String colCinema = 'cinema';
const String colTimings = 'timings';
const String colBookings = 'bookings';
const String colEvents = 'events';