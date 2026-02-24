import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});

  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final PageController _mainPageController = PageController();
  int _currentVehicleIndex = 0;

  @override
  void dispose() {
    _mainPageController.dispose();
    super.dispose();
  }

  // --- LOGICA NAVIGAZIONE ---
  void _navigateVehicles(int direction, int totalItems) {
    int nextIndex = _currentVehicleIndex + direction;
    if (nextIndex >= 0 && nextIndex < totalItems) {
      setState(() {
        _currentVehicleIndex = nextIndex;
      });
      _mainPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // --- LOGICA ELIMINAZIONE VEICOLO ---
  Future<void> _deleteVehicle(String vehicleId, String? imageUrl) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Elimina Veicolo"),
            content: const Text(
              "Sei sicuro di voler rimuovere questo veicolo dal tuo garage?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annulla"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Elimina",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        // 1. Elimina da Firestore
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .delete();

        // 2. Elimina immagine da Storage se esiste
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        }

        Navigator.pop(context); // Chiude il BottomSheet
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Veicolo eliminato")));
      } catch (e) {
        debugPrint("Errore durante l'eliminazione: $e");
      }
    }
  }

  // --- LOGICA CARICAMENTO IMMAGINE ---
  Future<String?> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return null;
    File file = File(image.path);
    String fileName =
        'vehicles/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref(fileName)
          .putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Errore: $e");
      return null;
    }
  }

  // --- POPUP DETTAGLI VEICOLO (Con tasto Elimina) ---
  void _showVehicleDetailsSheet(Map<String, dynamic> vehicle, String docId) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(25),
                children: [
                  Center(
                    child: vehicle['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              vehicle['imageUrl'],
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(
                            Icons.directions_car,
                            size: 80,
                            color: isDark ? Colors.white12 : Colors.grey[300],
                          ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      vehicle['nome'] ?? "Veicolo",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        "Cilindrata",
                        "${vehicle['cilindrata'] ?? '-'} cc",
                        isDark,
                      ),
                      _buildInfoChip("Anno", vehicle['anno'] ?? '-', isDark),
                      _buildInfoChip(
                        "Carburante",
                        vehicle['carburante'] ?? '-',
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 15),
                  const Text(
                    "Note",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle['note'] ?? "Nessuna nota",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // TASTO ELIMINA
                  TextButton.icon(
                    onPressed: () => _deleteVehicle(docId, vehicle['imageUrl']),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      "Elimina dal garage",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- POPUP AGGIUNTA VEICOLO (Stile Originale) ---
  void _showAddVehicleSheet() {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final PageController sheetPageController = PageController();
    final nomeController = TextEditingController();
    final cilindrataController = TextEditingController();
    final annoController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedCarburante;
    String? imageUrl;
    bool isUploading = false;
    int currentSheetPage = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Aggiunta di un veicolo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            "In questa sezione potrai aggiungere un veicolo al tuo garage...",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.black,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: sheetPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setModalState(() => currentSheetPage = index),
                  children: [
                    _buildStepImage(
                      setModalState,
                      imageUrl,
                      isUploading,
                      isDark,
                      () async {
                        setModalState(() => isUploading = true);
                        String? url = await _pickAndUploadImage();
                        setModalState(() {
                          imageUrl = url;
                          isUploading = false;
                        });
                      },
                    ),
                    _buildStepInfo(
                      nomeController,
                      cilindrataController,
                      annoController,
                      noteController,
                      selectedCarburante,
                      isDark,
                      (val) => setModalState(() => selectedCarburante = val),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(currentSheetPage == 0, isDark),
                        const SizedBox(width: 8),
                        _dot(currentSheetPage == 1, isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7D91),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () async {
                          if (currentSheetPage == 0) {
                            sheetPageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            await FirebaseFirestore.instance
                                .collection('vehicles')
                                .add({
                                  'uid': uid,
                                  'nome': nomeController.text.trim(),
                                  'cilindrata': cilindrataController.text
                                      .trim(),
                                  'anno': annoController.text.trim(),
                                  'carburante': selectedCarburante,
                                  'note': noteController.text.trim(),
                                  'imageUrl': imageUrl,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          currentSheetPage == 0
                              ? "Continua"
                              : "Aggiungi veicolo",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF1F3F4),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehicles')
              .where('uid', isEqualTo: uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty)
              return Center(
                child: Text(
                  "Garage vuoto",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              );

            if (_currentVehicleIndex >= docs.length)
              _currentVehicleIndex = docs.length - 1;

            return Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  "I tuoi veicoli",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PageView.builder(
                        controller: _mainPageController,
                        itemCount: docs.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          var v = docs[index].data() as Map<String, dynamic>;
                          return Center(
                            child: v['imageUrl'] != null
                                ? Image.network(
                                    v['imageUrl'],
                                    width: 320,
                                    fit: BoxFit.contain,
                                  )
                                : Icon(
                                    Icons.directions_car,
                                    size: 120,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey[300],
                                  ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          var currentVehicleData =
                              docs[_currentVehicleIndex].data()
                                  as Map<String, dynamic>;
                          var docId = docs[_currentVehicleIndex]
                              .id; // PRENDIAMO L'ID PER ELIMINARE
                          _showVehicleDetailsSheet(currentVehicleData, docId);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(width: 300, height: 350),
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
                      Positioned(
                        bottom: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            docs.length,
                            (index) =>
                                _dot(_currentVehicleIndex == index, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton(
          onPressed: _showAddVehicleSheet,
          backgroundColor: isDark ? Colors.white : const Color(0xFF333333),
          child: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStepImage(
    StateSetter setModalState,
    String? imageUrl,
    bool isUploading,
    bool isDark,
    VoidCallback onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Text(
            "Inserisci un'immagine del veicolo\nda aggiungere al garage (facoltativo)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[200]!,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (imageUrl == null) ...[
                        Icon(
                          Icons.description_outlined,
                          size: 50,
                          color: isDark ? Colors.white24 : Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Inserisci un immagine con sfondo bianco",
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white12
                                : const Color(0xFF333333),
                          ),
                          onPressed: onPick,
                          child: Text(
                            "Carica",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.white,
                            ),
                          ),
                        ),
                      ] else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            height: 248,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo(
    TextEditingController nome,
    TextEditingController cil,
    TextEditingController anno,
    TextEditingController note,
    String? carburante,
    bool isDark,
    Function(String?) onCarburanteChanged,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Text(
            "Inserisci le informazioni sul\nveicolo (facoltativo)",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(nome, "Nome", isDark),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildTextField(cil, "Cilindrata", isDark)),
              const SizedBox(width: 15),
              Expanded(
                child: _buildTextField(anno, "Anno di rilascio", isDark),
              ),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: carburante,
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Carburante",
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              border: const OutlineInputBorder(),
            ),
            items: [
              "Benzina",
              "Diesel",
              "Elettrica",
              "Ibrida",
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onCarburanteChanged,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            note,
            "Segni particolari (facoltativo)",
            isDark,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
        border: const OutlineInputBorder(),
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
          size: 22,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _dot(bool isActive, bool isDark) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 8,
    height: 8,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isActive
          ? (isDark ? Colors.white : Colors.black)
          : (isDark ? Colors.white12 : Colors.grey[300]),
    ),
  );

  Widget _buildInfoChip(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeTile(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Color(0xFF4A7D91)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Esempio Scambio",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Text(
                "Dati non disponibili",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
