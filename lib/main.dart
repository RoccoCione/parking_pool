// main.dart modificato
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parking_pool/presentation/pages/main_wrapper.dart';
import 'firebase_options.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/auth_page.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking Pool',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Se hai un font specifico da Figma
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7D91)),
      ),
      // Definiamo le rotte nominate per comodità
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
        '/home': (context) => MainWrapper(), 
      },
      home: const SplashScreen(), // Partiamo sempre dalla Splash
    );
  }
}