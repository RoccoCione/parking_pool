import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'map_page.dart';
import '../../environmental_calculator.dart';
import '../widgets/temp_chat_widget.dart';

class ExitParkingSheet extends StatefulWidget {
  const ExitParkingSheet({super.key});

  @override
  State<ExitParkingSheet> createState() => _ExitParkingSheetState();
}

class _ExitParkingSheetState extends State<ExitParkingSheet> {
  bool _isPublished = false;
  int _selectedTimer = 5;
  bool _isAnonymous = false;
  bool _acceptChatRequest = false;
  int _currentVehicleIndex = 0;
  String? _currentSlotId;
  String? _activeRequestId;

  // Flag critico per evitare che il cleanup venga chiamato più volte
  bool _isCleaningUp = false;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final PageController _vehicleController = PageController();

  @override
  void initState() {
    super.initState();
    MapPage.globalController?.runJavaScript("window.setSelectionMode(true)");
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    MapPage.globalController?.runJavaScript("window.setSelectionMode(false)");
    _vehicleController.dispose();
    super.dispose();
  }

  void _forceExit() {
    MapPage.globalController?.runJavaScript("window.setSelectionMode(false)");
    MapPage.globalController?.runJavaScript("window.removeParkingMarker()");
    if (mounted) Navigator.pop(context);
  }

  // --- LOGICA FIRESTORE ---

  Future<void> _publishToFirestore(Map<String, dynamic> vehicleData) async {
    double lat = MapPage.lastLat ?? 40.7725;
    double lng = MapPage.lastLng ?? 14.7915;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final docRef = await FirebaseFirestore.instance
          .collection('active_slots')
          .add({
            'uid': uid,
            'username': userData['username'] ?? 'Utente',
            'nome': userData['nome'] ?? '',
            'cognome': userData['cognome'] ?? '',
            'nome_veicolo': vehicleData['nome'] ?? 'Veicolo',
            'imageUrl': vehicleData['imageUrl'],
            'timer_iniziale': _selectedTimer,
            'timestamp': FieldValue.serverTimestamp(),
            'is_anonymous': _isAnonymous,
            'status': 'available',
            'lat': lat,
            'lng': lng,
          });

      if (mounted) {
        setState(() {
          _currentSlotId = docRef.id;
          _isPublished = true;
        });
        _startCountdown();
        MapPage.globalController?.runJavaScript(
          "window.setSelectionMode(false)",
        );
      }
    } catch (e) {
      debugPrint("Errore pubblicazione: $e");
    }
  }

  Future<void> _removeFromFirestore(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('active_slots')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint("Errore rimozione: $e");
    }
  }

  Future<void> _handleRequest(
    String requestId,
    String newStatus,
    bool chatAccepted,
  ) async {
    if (newStatus == 'rejected') {
      await FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(requestId)
          .delete();
    } else if (newStatus == 'accepted') {
      _countdownTimer?.cancel();
      setState(() => _activeRequestId = requestId);

      await FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(requestId)
          .update({
            'status': 'in_progress',
            'owner_chat_consent': chatAccepted,
            'confirmation_outgoing': false,
            'confirmation_incoming': false,
          });

      if (_currentSlotId != null) {
        await FirebaseFirestore.instance
            .collection('active_slots')
            .doc(_currentSlotId!)
            .update({'status': 'occupied'});
      }
    }
  }

  Future<void> _confirmExchange() async {
    if (_activeRequestId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(_activeRequestId)
          .update({'confirmation_outgoing': true});
    } catch (e) {
      debugPrint("Errore conferma uscita: $e");
    }
  }

  Future<void> _handleFinalCleanup(Map<String, dynamic> data) async {
    if (_isCleaningUp) return;
    _isCleaningUp = true;

    try {
      final String requesterUid = data['requester_uid'];

      // Calcolo impatto ambientale
      final vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('uid', isEqualTo: requesterUid)
          .limit(1)
          .get();

      double risparmioEuro = 0.45;
      double risparmioCO2 = 0.60;

      if (vehicleSnapshot.docs.isNotEmpty) {
        var vData = vehicleSnapshot.docs.first.data();

        // Recupero cilindrata gestendo sia String che Number
        dynamic cilindrataRaw = vData['cilindrata'] ?? 1.2;
        double cilindrataPulita;

        if (cilindrataRaw is String) {
          cilindrataPulita = double.tryParse(cilindrataRaw) ?? 1.2;
        } else {
          cilindrataPulita = (cilindrataRaw as num).toDouble();
        }

        var impact = EnvironmentalCalculator.getImpact(
          cilindrata: cilindrataPulita, // Ora è sicuramente un double
          carburante: vData['carburante'] ?? 'Benzina',
          anno: vData['anno'] ?? 2018,
        );
        risparmioEuro = impact['euro']!;
        risparmioCO2 = impact['co2']!;
      }

      // Batch update per atomicità (opzionale ma consigliato)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.update(FirebaseFirestore.instance.collection('users').doc(uid), {
        'posti_ceduti': FieldValue.increment(1),
      });

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(requesterUid),
        {
          'posti_ricevuti': FieldValue.increment(1),
          'risparmio': FieldValue.increment(risparmioEuro),
          'tempo': FieldValue.increment(5),
          'co2_risparmiata': FieldValue.increment(risparmioCO2),
        },
      );

      DocumentReference completedRef = FirebaseFirestore.instance
          .collection('completed_exchanges')
          .doc();
      batch.set(completedRef, {
        'slot_id': _currentSlotId,
        'requester_uid': requesterUid,
        'owner_uid': uid,
        'euro_risparmiati': risparmioEuro,
        'co2_risparmiata': risparmioCO2,
        'timestamp_completion': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Pulizia documenti attivi
      if (_currentSlotId != null) await _removeFromFirestore(_currentSlotId!);
      if (_activeRequestId != null) {
        await FirebaseFirestore.instance
            .collection('exchange_requests')
            .doc(_activeRequestId!)
            .delete();
      }

      if (mounted) {
        _forceExit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Scambio completato!"),
            backgroundColor: Color(0xFF4A7D91),
          ),
        );
      }
    } catch (e) {
      debugPrint("Errore cleanup: $e");
      _isCleaningUp = false; // Permette di riprovare in caso di errore di rete
    }
  }

  Future<void> _failExchange() async {
    if (_activeRequestId == null) return;
    await FirebaseFirestore.instance
        .collection('exchange_requests')
        .doc(_activeRequestId)
        .delete();
    _forceExit();
  }

  void _startCountdown() {
    _remainingSeconds = _selectedTimer * 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _forceExit();
      }
    });
  }

  Future<bool> _showCancelConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Annullare avviso?"),
            content: const Text(
              "Se esci ora, la segnalazione del tuo parcheggio verrà rimossa.",
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    return PopScope(
      canPop: !_isPublished && _activeRequestId == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_activeRequestId != null) return;
        final shouldPop = await _showCancelConfirmation();
        if (shouldPop) {
          if (_currentSlotId != null)
            await _removeFromFirestore(_currentSlotId!);
          _forceExit();
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
              child: _activeRequestId != null
                  ? _buildExchangeInProgressView(isDark)
                  : _isPublished
                  ? _buildWaitingView(isDark)
                  : _buildSetupStream(isDark),
            ),
            if (!_isPublished && _activeRequestId == null)
              _buildFooterButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeInProgressView(bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchange_requests')
          .doc(_activeRequestId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool outConfirmed = data['confirmation_outgoing'] ?? false;
        bool inConfirmed = data['confirmation_incoming'] ?? false;

        // Se entrambi confermano, avviamo il cleanup una sola volta
        if (outConfirmed && inConfirmed && !_isCleaningUp) {
          Future.microtask(() => _handleFinalCleanup(data));
        }

        return _buildInProgressUI(isDark, outConfirmed, data);
      },
    );
  }

  Widget _buildInProgressUI(
    bool isDark,
    bool outConfirmed,
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
          if (chatEnabled && _activeRequestId != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TempChatWidget(
                requestId: _activeRequestId!,
                currentUid: uid!,
                isDark: isDark,
              ),
            )
          else if (!chatEnabled)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  "Chat non attivata.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          if (outConfirmed)
            const Column(
              children: [
                CircularProgressIndicator(color: Colors.green),
                SizedBox(height: 20),
                Text(
                  "In attesa dell'altro utente...",
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
                "IL POSTO È ORA LIBERO",
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

  Widget _buildWaitingView(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchange_requests')
          .where('slot_id', isEqualTo: _currentSlotId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var reqData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          return _buildRequestReceivedView(
            isDark,
            reqData,
            snapshot.data!.docs.first.id,
          );
        }
        return Column(
          children: [
            const SizedBox(height: 60),
            const CircularProgressIndicator(color: Color(0xFF4A7D91)),
            const SizedBox(height: 30),
            const Text(
              "Il tuo posto è ora visibile sulla mappa",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            _buildTimerDisplay(isDark),
            _buildCancelButton(),
          ],
        );
      },
    );
  }

  Widget _buildRequestReceivedView(
    bool isDark,
    Map<String, dynamic> data,
    String requestId,
  ) {
    bool anonymous = data['is_anonymous'] ?? false;
    String username = data['requester_username'] ?? "Utente";
    int minutiArrivo = data['timer_richiesto'] ?? 5;
    bool requesterWantsChat = data['request_chat'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Richiesta di scambio ricevuta!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 30),
          const CircleAvatar(
            radius: 55,
            backgroundColor: Color(0xFF4A7D91),
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            username,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (!anonymous) ...[
            Text(
              "${data['requester_nome']} ${data['requester_cognome']}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "In arrivo con: ${data['requester_veicolo']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              "L'utente ha scelto la modalità anonima",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_filled,
                color: Color(0xFF4A7D91),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Arriva tra: ",
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Text(
                "$minutiArrivo min",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A7D91),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          if (requesterWantsChat) ...[
            const SizedBox(height: 10),
            const Text(
              "L'altro utente ha richiesto la chat",
              style: TextStyle(
                color: Color(0xFF4A7D91),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            _buildCustomToggle(
              "Accetta Chat Temporanea",
              _acceptChatRequest,
              (val) => setState(() => _acceptChatRequest = val),
              isDark,
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7D91),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () =>
                _handleRequest(requestId, 'accepted', _acceptChatRequest),
            child: const Text(
              "ACCETTA SCAMBIO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _handleRequest(requestId, 'rejected', false),
            child: const Text(
              "Rifiuta",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Avviso di parcheggio",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Pubblica la tua posizione per liberare il posto.",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _isPublished
                ? _showCancelConfirmation().then((v) => v ? _forceExit() : null)
                : _forceExit(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStream(bool isDark) {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                "Scegli il veicolo",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
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
                                size: 120,
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
                        () => _vehicleController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        ),
                        isDark,
                      ),
                    ),
                  if (_currentVehicleIndex < docs.length - 1)
                    Positioned(
                      right: 15,
                      child: _buildNavArrow(
                        Icons.arrow_forward_ios,
                        () => _vehicleController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        ),
                        isDark,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              docs[_currentVehicleIndex]['nome'] ?? 'Veicolo',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildDots(docs.length, isDark),
            _buildAnonymousToggle(isDark),
            _buildTimerPicker(isDark),
          ],
        );
      },
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

  Widget _buildAnonymousToggle(bool isDark) {
    return _buildCustomToggle(
      "Modalità Anonimo",
      _isAnonymous,
      (val) => setState(() => _isAnonymous = val),
      isDark,
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
          const Text("Timer", style: TextStyle(fontWeight: FontWeight.bold)),
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
          backgroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () async {
          final snapshot = await FirebaseFirestore.instance
              .collection('vehicles')
              .where('uid', isEqualTo: uid)
              .get();
          if (snapshot.docs.isNotEmpty)
            _publishToFirestore(snapshot.docs[_currentVehicleIndex].data());
        },
        child: const Text(
          "Pubblica avviso",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: () async {
          if (await _showCancelConfirmation()) {
            if (_currentSlotId != null)
              await _removeFromFirestore(_currentSlotId!);
            _forceExit();
          }
        },
        child: const Text(
          "Rimuovi avviso",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            '${(_remainingSeconds ~/ 60)}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
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
}
