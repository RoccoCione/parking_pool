import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'map_page.dart';
import '../widgets/temp_chat_widget.dart';

class EnterParkingSheet extends StatefulWidget {
  final String slotId;
  const EnterParkingSheet({super.key, required this.slotId});

  @override
  State<EnterParkingSheet> createState() => _EnterParkingSheetState();
}

class _EnterParkingSheetState extends State<EnterParkingSheet> {
  bool _isRequestSent = false;
  String? _requestId;
  bool _isManuallyCancelled = false;
  bool _isInProgress =
      false; // Flag per capire se siamo in fase di scambio attivo

  int _selectedTimer = 5;
  bool _isAnonymous = false;
  bool _requestChat = true;
  int _currentVehicleIndex = 0;

  final PageController _vehicleController = PageController();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    MapPage.globalController?.runJavaScript("window.setSelectionMode(false)");
    _vehicleController.dispose();
    super.dispose();
  }

  void _safePop() {
    MapPage.globalController?.runJavaScript("window.setSelectionMode(false)");
    if (mounted) Navigator.pop(context);
  }

  // --- LOGICA AVVISI PERSONALIZZATI ---
  void _closeSheetWithAlert(String message, Color color) {
    if (mounted) {
      _safePop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- LOGICA FIRESTORE ---

  Future<void> _sendRequest() async {
    try {
      if (uid == null) return;
      _isManuallyCancelled = false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('uid', isEqualTo: uid)
          .get();

      if (vehicleSnapshot.docs.isEmpty) return;
      final vehicleData = vehicleSnapshot.docs[_currentVehicleIndex].data();

      final docRef = await FirebaseFirestore.instance
          .collection('exchange_requests')
          .add({
            'slot_id': widget.slotId,
            'requester_uid': uid,
            'requester_username': userData['username'] ?? 'Utente',
            'requester_nome': userData['nome'] ?? '',
            'requester_cognome': userData['cognome'] ?? '',
            'requester_veicolo': vehicleData['nome'] ?? 'Veicolo',
            'status': 'pending',
            'is_anonymous': _isAnonymous,
            'request_chat': _requestChat,
            'timer_richiesto': _selectedTimer,
            'confirmation_outgoing': false,
            'confirmation_incoming': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

      setState(() {
        _requestId = docRef.id;
        _isRequestSent = true;
      });
    } catch (e) {
      debugPrint("Errore invio richiesta: $e");
    }
  }

  Future<void> _confirmExchange() async {
    if (_requestId == null) return;
    await FirebaseFirestore.instance
        .collection('exchange_requests')
        .doc(_requestId)
        .update({'confirmation_incoming': true});
  }

  // MODIFICATO: Logica per gestire Annullamento vs Fallimento
  Future<void> _failExchange() async {
    if (_requestId == null) {
      _safePop();
      return;
    }

    setState(() => _isManuallyCancelled = true);

    await FirebaseFirestore.instance
        .collection('exchange_requests')
        .doc(_requestId)
        .delete();

    // Se eravamo già in "in_progress", l'alert deve essere "Scambio fallito"
    if (_isInProgress) {
      _closeSheetWithAlert("Scambio fallito", Colors.redAccent);
    } else {
      _closeSheetWithAlert("Richiesta annullata", Colors.grey[700]!);
    }
  }

  void _navigateVehicles(int direction, int totalItems) {
    int nextIndex = _currentVehicleIndex + direction;
    if (nextIndex >= 0 && nextIndex < totalItems) {
      _vehicleController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    return PopScope(
      canPop: !_isRequestSent,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        MapPage.globalController?.runJavaScript(
          "window.setSelectionMode(false)",
        );
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
              child: _isRequestSent
                  ? _buildWaitingOrExchangeStream(isDark)
                  : _buildSetupBody(isDark),
            ),
            if (!_isRequestSent) _buildFooterButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupBody(bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('active_slots')
          .doc(widget.slotId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) {
          return const Center(child: Text("Posto non più disponibile"));
        }
        var slotData = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildUserInfoSection(slotData, isDark),
            _buildOptionsSection(isDark),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                "Scegli il tuo veicolo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            SizedBox(height: 250, child: _buildVehicleSelectionPage(isDark)),
          ],
        );
      },
    );
  }

  Widget _buildWaitingOrExchangeStream(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(_requestId)
          .snapshots(),
      builder: (context, snapshot) {
        // --- LOGICA DI CHIUSURA FORZATA / SPARIZIONE DOC ---
        if (!snapshot.hasData || !snapshot.data!.exists) {
          if (_requestId != null &&
              snapshot.connectionState == ConnectionState.active) {
            // Se il documento sparisce ma non è stato annullato manualmente da noi con _failExchange
            if (!_isManuallyCancelled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Se sparisce e non eravamo in uno stato di successo confermato,
                // chiudiamo con errore invece di successo.
                _closeSheetWithAlert(
                  _isInProgress
                      ? "Scambio interrotto o fallito"
                      : "Richiesta non più valida",
                  Colors.redAccent,
                );
              });
            }
          }
          return const Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'pending';
        bool outConfirmed = data['confirmation_outgoing'] ?? false;
        bool inConfirmed = data['confirmation_incoming'] ?? false;

        // Aggiornamento flag in_progress
        if (status == 'in_progress' && !_isInProgress) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isInProgress = true);
          });
        }

        // --- CASO 1: SUCCESSO REALE ---
        // Solo quando entrambi hanno cliccato sui rispettivi pulsanti di conferma
        if (outConfirmed && inConfirmed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Usiamo un flag temporaneo per evitare loop di alert
            if (!_isManuallyCancelled) {
              _closeSheetWithAlert("Posto preso con successo!", Colors.green);
            }
          });
        }

        // --- CASO 2: RIFIUTO ESPLICITO ---
        if (status == 'rejected') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _closeSheetWithAlert(
              "La richiesta è stata rifiutata dall'altro utente",
              Colors.redAccent,
            );
          });
        }

        // Visualizzazione UI in base allo stato
        if (status == 'in_progress') {
          return _buildInProgressUI(isDark, inConfirmed, data);
        }

        return _buildPendingUI(isDark);
      },
    );
  }
  
  // --- UI WIDGETS ---

  Widget _buildUserInfoSection(Map<String, dynamic> slotData, bool isDark) {
    bool anonymous = slotData['is_anonymous'] ?? false;
    String username = slotData['username'] ?? "Utente";
    String nomeCompleto =
        "${slotData['nome'] ?? ''} ${slotData['cognome'] ?? ''}";
    String veicolo = slotData['nome_veicolo'] ?? "Veicolo";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF4A7D91).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF4A7D91), size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (!anonymous) ...[
                  Text(
                    nomeCompleto,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    "Veicolo: $veicolo",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else
                  const Text(
                    "Modalità anonima attiva",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          _buildCustomToggle(
            "Modalità Anonimo",
            _isAnonymous,
            (val) => setState(() => _isAnonymous = val),
            isDark,
          ),
          _buildCustomToggle(
            "Richiedi Chat",
            _requestChat,
            (val) => setState(() => _requestChat = val),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomToggle(
    String title,
    bool value,
    Function(bool) onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => onTap(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: const Color(0xFF4A7D91),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelectionPage(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text("Nessun veicolo trovato"));
        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _vehicleController,
                    onPageChanged: (index) =>
                        setState(() => _currentVehicleIndex = index),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var v = docs[index].data() as Map<String, dynamic>;
                      return Center(
                        child: v['imageUrl'] != null
                            ? Image.network(v['imageUrl'], fit: BoxFit.contain)
                            : Icon(
                                Icons.directions_car,
                                size: 100,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[300],
                              ),
                      );
                    },
                  ),
                  if (_currentVehicleIndex > 0)
                    Positioned(
                      left: 15,
                      child: _buildNavArrow(
                        Icons.arrow_back_ios_new,
                        () => _navigateVehicles(-1, docs.length),
                        isDark,
                      ),
                    ),
                  if (_currentVehicleIndex < docs.length - 1)
                    Positioned(
                      right: 15,
                      child: _buildNavArrow(
                        Icons.arrow_forward_ios,
                        () => _navigateVehicles(1, docs.length),
                        isDark,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              docs[_currentVehicleIndex]['nome'] ?? 'Veicolo',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildDots(docs.length, isDark),
            _buildTimerPicker(isDark),
          ],
        );
      },
    );
  }

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
            child: const Icon(Icons.search, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dettagli Posto",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Text(
                  "Invia una richiesta per questo parcheggio.",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _safePop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onPressed, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.black54,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDots(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentVehicleIndex == i
                ? (isDark ? Colors.white : Colors.black)
                : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerPicker(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text(
            "Timer arrivo",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text("$_selectedTimer min"),
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

  Widget _buildFooterButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A7D91),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: _sendRequest,
        child: const Text(
          "MANDA RICHIESTA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInProgressUI(
    bool isDark,
    bool inConfirmed,
    Map<String, dynamic> data,
  ) {
    bool ownerConsent = data['owner_chat_consent'] ?? false;
    bool requesterConsent = data['request_chat'] ?? false;
    bool chatEnabled = ownerConsent && requesterConsent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Scambio in corso!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          if (!chatEnabled) ...[
            const SizedBox(height: 30),
            const Icon(
              Icons.handshake_rounded,
              size: 100,
              color: Color(0xFF4A7D91),
            ),
            const SizedBox(height: 20),
          ],
          if (chatEnabled && _requestId != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TempChatWidget(
                requestId: _requestId!,
                currentUid: uid!,
                isDark: isDark,
              ),
            )
          else if (!chatEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  "Chat non attivata per questo scambio.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),

          if (inConfirmed)
            const Column(
              children: [
                CircularProgressIndicator(color: Color(0xFF4A7D91)),
                SizedBox(height: 20),
                Text(
                  "In attesa della conferma finale...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          else ...[
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _confirmExchange,
              child: const Text(
                "HO PRESO IL POSTO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _failExchange,
              child: const Text(
                "SCAMBIO FALLITO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPendingUI(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF4A7D91)),
        const SizedBox(height: 30),
        const Text(
          "Richiesta inviata. In attesa...",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        TextButton(
          onPressed: _failExchange,
          child: const Text(
            "Annulla richiesta",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
