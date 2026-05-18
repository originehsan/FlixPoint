import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/provider/moviedetails.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/splashscreen.dart';
import 'firebase_options.dart';
import 'package:movieticket/utils/color.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Movie(),
        ),
        ChangeNotifierProvider(
          // Removed ..initialize() - handled in splashscreen
          create: (context) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => MovieProvider()..loadAllMovies(),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingProvider(),
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
