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
      debugPrint("Errore caricamento foto: $e");
      return null;
    }
  }

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
              // Header
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
                            "Inserisci i dettagli del tuo veicolo",
                            style: TextStyle(
                              fontSize: 11,
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
                        size: 28,
                        color: isDark ? Colors.white70 : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Contenuto (PageView)
              Expanded(
                child: PageView(
                  controller: sheetPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setModalState(() => currentSheetPage = index),
                  children: [
                    // Step 1: Immagine
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
                    // Step 2: Dati Completi (Cilindrata, Anno, Carburante, Note)
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

              // Footer
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
                            borderRadius: BorderRadius.circular(20),
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
                                  'nome': nomeController.text.trim().isEmpty
                                      ? "Nuovo Veicolo"
                                      : nomeController.text.trim(),
                                  'cilindrata': cilindrataController.text
                                      .trim(),
                                  'anno': annoController.text.trim(),
                                  'carburante': selectedCarburante ?? "N/D",
                                  'note': noteController.text.trim(),
                                  'imageUrl': imageUrl,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          currentSheetPage == 0 ? "Continua" : "Salva veicolo",
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
        child: Column(
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicles')
                    .where('uid', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty)
                    return Center(
                      child: Text(
                        "Nessun veicolo nel garage",
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    );

                  return Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _mainPageController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          onPageChanged: (index) =>
                              setState(() => _currentVehicleIndex = index),
                          itemCount: docs.length,
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
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          docs.length,
                          (index) =>
                              _dot(_currentVehicleIndex == index, isDark),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  );
                },
              ),
            ),
          ],
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
    StateSetter setState,
    String? imageUrl,
    bool isUploading,
    bool isDark,
    VoidCallback onPick,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          "Carica Foto",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 220,
            width: 280,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : (imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        )
                      : Icon(
                          Icons.add_a_photo_outlined,
                          size: 50,
                          color: isDark ? Colors.white24 : Colors.grey,
                        )),
          ),
        ),
      ],
    );
  }

  // RIPRISTINATO IL FORM ORIGINALE
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
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildDarkTextField(nome, "Nome Modello", isDark),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildDarkTextField(cil, "Cilindrata", isDark)),
              const SizedBox(width: 20),
              Expanded(child: _buildDarkTextField(anno, "Anno", isDark)),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: carburante,
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: "Carburante",
              labelStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey[300]!,
                ),
              ),
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
          _buildDarkTextField(
            note,
            "Note / Segni particolari",
            isDark,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDarkTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4A7D91)),
        ),
      ),
    );
  }

  Widget _dot(bool isActive, bool isDark) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: isActive ? 20 : 8,
    height: 8,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: isActive
          ? (isDark ? Colors.white : Colors.black)
          : (isDark ? Colors.white12 : Colors.grey[300]),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
