import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/provider/moviedetails.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/splashscreen.dart';
import 'package:movieticket/services/hive_service.dart';
import 'package:movieticket/services/network_service.dart';
import 'package:movieticket/services/tmdb_service.dart';
import 'package:movieticket/utils/color.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  // BUG 9 fix: preserve native splash
  // while all init completes
  final widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(
    widgetsBinding: widgetsBinding,
  );

  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // BUG 9 fix: open ALL Hive boxes
  // before runApp — never lazy open
  await Hive.initFlutter();
  await HiveService.openAllBoxes();

  // Network + TMDB
  NetworkService().initialize();
  TmdbService().initialize();

  // All init done — remove native splash
  // SplashScreen animation takes over
  FlutterNativeSplash.remove();

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
          scaffoldBackgroundColor:
              mobileBackgroundColor,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}