import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'exit_parking_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    // Usiamo LayoutBuilder per conoscere l'altezza esatta dello schermo disponibile
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // LIVELLO 0: LA MAPPA (Sfondo totale)
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F4),
              child: const Center(
                child: Text(
                  "MAPPA",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // LIVELLO 1: NOME UTENTE (In alto)
            Positioned(
              top: 60,
              left: 20,
              child: Material(
                // Material serve per far renderizzare il testo correttamente dentro uno Stack
                color: Colors.transparent,
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var userData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    return Text(
                      'Ciao, ${userData['nome'] ?? 'Utente'}!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    );
                  },
                ),
              ),
            ),

            // LIVELLO 2: PULSANTE NERO "ESCO"
            // Lo posizioniamo a metà altezza per essere sicuri di vederlo, poi lo abbasseremo
            Positioned(
              bottom:
                  120, // Se non lo vedi, prova ad aumentare questo numero a 200
              right: 20,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ExitParkingSheet(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black, // Nero come richiesto
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "ESCO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
