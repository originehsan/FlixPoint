import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movieticket/provider/booking_provider.dart';
import 'package:movieticket/provider/movie_provider.dart';
import 'package:movieticket/provider/moviedetails.dart';
import 'package:movieticket/provider/user_provider.dart';
import 'package:movieticket/screens/splashscreen.dart';
import 'package:movieticket/utils/dimension.dart';
import 'firebase_options.dart';
import 'package:movieticket/utils/color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    return ScreenUtilInit(
      designSize: AppDimensions.screenSize,
      minTextAdapt: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => Movie(),
            ),
            ChangeNotifierProvider(
              create: (context) => UserProvider()..initialize(),
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
      },
    );
  }
}