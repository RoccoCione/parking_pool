import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import necessario per il tema
import 'package:parking_pool/presentation/pages/main_wrapper.dart';
import 'firebase_options.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/auth_page.dart';

// --- SERVICE PER IL TEMA (Puoi metterlo anche in un file separato theme_service.dart) ---
class ThemeService extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Definiamo i colori base per coerenza
  static const Color brandColor = Color(0xFF4A7D91);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    // Avvolgiamo l'app con il Provider per il Tema
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo il servizio del tema
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking Pool',
      
      // CONFIGURAZIONE TEMA LIGHT
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeService.brandColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),

      // CONFIGURAZIONE TEMA DARK
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ThemeService.brandColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      // Impostiamo quale tema usare in base allo stato del service
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const MainWrapper(), 
      },
      home: const SplashScreen(),
    );
  }
}