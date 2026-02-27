import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'map_page.dart';

class ExitParkingSheet extends StatefulWidget {
  const ExitParkingSheet({super.key});

  @override
  State<ExitParkingSheet> createState() => _ExitParkingSheetState();
}

class _ExitParkingSheetState extends State<ExitParkingSheet> {
  // Stati della UI
  bool _isPublished = false;
  int _selectedTimer = 5;
  bool _isAnonymous = false;
  int _currentVehicleIndex = 0;

  // Logica Countdown
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final PageController _vehicleController = PageController();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _vehicleController.dispose();
    super.dispose();
  }

  // Funzione centralizzata per rimuovere il marker e chiudere
  void _cancelAndCleanup() {
    _countdownTimer?.cancel();
    MapPage.globalController?.runJavaScript("window.removeParkingMarker()");
    if (mounted) Navigator.pop(context);
  }

  // Dialog di conferma per l'annullamento
  Future<bool> _showCancelConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Annullare avviso?"),
            content: const Text(
              "Se esci ora, la segnalazione del tuo parcheggio verrà rimossa dalla mappa.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("NO, RESTA"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "SÌ, ANNULLA",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _startCountdown() {
    _remainingSeconds = _selectedTimer * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        // Alla scadenza, puliamo la mappa e chiudiamo
        _cancelAndCleanup();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    // PopScope impedisce la chiusura accidentale tramite gesture (swipe down o back button)
    return PopScope(
      canPop:
          !_isPublished, // Permette di chiudere liberamente solo se NON è pubblicato
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Se è pubblicato e l'utente prova a chiudere, chiediamo conferma
        final shouldPop = await _showCancelConfirmation();
        if (shouldPop) {
          _cancelAndCleanup();
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isPublished
                  ? _buildWaitingView(isDark)
                  : _buildSetupView(isDark),
            ),
            _buildFooterButton(isDark),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTI UI ---

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7D91),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_parking,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Avviso di parcheggio",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  _isPublished
                      ? "In attesa di un altro utente..."
                      : "Pubblica la tua posizione per liberare il posto.",
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              if (_isPublished) {
                if (await _showCancelConfirmation()) _cancelAndCleanup();
              } else {
                // Se non è pubblicato, rimuoviamo comunque il marker che l'utente ha messo sulla mappa
                MapPage.globalController?.runJavaScript(
                  "window.removeParkingMarker()",
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(bool isDark) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text(
            "Scegli il veicolo con cui stai lasciando il parcheggio",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vehicles')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("Nessun veicolo nel garage"));
              }

              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _vehicleController,
                      onPageChanged: (i) =>
                          setState(() => _currentVehicleIndex = i),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var v = docs[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: v['imageUrl'] != null
                              ? Image.network(
                                  v['imageUrl'],
                                  fit: BoxFit.contain,
                                )
                              : const Icon(Icons.directions_car, size: 100),
                        );
                      },
                    ),
                  ),
                  Text(
                    docs[_currentVehicleIndex]['nome'] ?? 'Veicolo',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDots(docs.length, isDark),
                ],
              );
            },
          ),
        ),
        _buildAnonymousToggle(isDark),
        _buildTimerPicker(isDark),
      ],
    );
  }

  Widget _buildWaitingView(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: Color(0xFF4A7D91),
          strokeWidth: 3,
        ),
        const SizedBox(height: 30),
        Text(
          "Il tuo posto è ora visibile sulla mappa",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const Text(
          "In attesa di matching...",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const Spacer(),
        _buildTimerDisplay(isDark),
      ],
    );
  }

  Widget _buildTimerPicker(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text("Timer", style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("$_selectedTimer min", style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () =>
                setState(() => _selectedTimer > 1 ? _selectedTimer-- : null),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedTimer++),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text(
            "Tempo rimanente",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            _formatTime(_remainingSeconds),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousToggle(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isAnonymous ? Icons.check_circle : Icons.radio_button_unchecked,
            color: const Color(0xFF4A7D91),
          ),
          const SizedBox(width: 8),
          Text(
            "Modalità Anonimo",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPublished ? Colors.redAccent : Colors.black,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 5,
        ),
        onPressed: () async {
          if (_isPublished) {
            if (await _showCancelConfirmation()) {
              _cancelAndCleanup();
            }
          } else {
            setState(() {
              _isPublished = true;
              _startCountdown();
            });
            // Qui andrebbe la logica per salvare il documento su Firestore
          }
        },
        child: Text(
          _isPublished ? "Rimuovi avviso" : "Pubblica avviso",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDots(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentVehicleIndex == i
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
