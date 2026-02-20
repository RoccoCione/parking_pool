import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      // Controlliamo lo stato dell'autenticazione in tempo reale
      final user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        if (user != null) {
          // L'utente è loggato! Vai in Home
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Nessun utente, vai al Login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Sfondo con la sfumatura blu/azzurra in basso a destra
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 255, 255, 255), // Chiaro in alto
                    Color(0xFF4A7D91), // Blu in basso
                  ],
                  stops: [0.4, 1.0], // La sfumatura inizia a metà schermo
                ),
              ),
            ),
          ),

          // Logo posizionato nella parte alta (non al centro perfetto)
          Align(
            alignment: const Alignment(
              0,
              -0.4,
            ), // -1 è l'estremità superiore, 0 è il centro
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width:
                      MediaQuery.of(context).size.width *
                      0.5, // 50% della larghezza schermo
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
