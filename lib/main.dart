import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/provider/moviedetails.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/splashscreen.dart';
import 'package:movieticket/services/network_service.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'firebase_options.dart';
import 'package:movieticket/utils/color.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('news_cache');

  // Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Network + TMDB
  NetworkService().initialize();
  TmdbService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Movie(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MovieProvider()
            ..loadAllMovies(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: mobileBackgroundColor,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}