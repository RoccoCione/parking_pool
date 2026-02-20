import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return null;
    File file = File(image.path);
    String fileName = 'vehicles/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(file);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Errore caricamento foto: $e");
      return null;
    }
  }

  void _showAddVehicleSheet() {
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.directions_car, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Aggiunta di un veicolo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Inserisci i dettagli del tuo veicolo nel garage", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 28))
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: sheetPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setModalState(() => currentSheetPage = index),
                  children: [
                    _buildStepImage(setModalState, imageUrl, isUploading, () async {
                      setModalState(() => isUploading = true);
                      String? url = await _pickAndUploadImage();
                      setModalState(() { imageUrl = url; isUploading = false; });
                    }),
                    _buildStepInfo(nomeController, cilindrataController, annoController, noteController, selectedCarburante, (val) => setModalState(() => selectedCarburante = val)),
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
                        _dot(currentSheetPage == 0),
                        const SizedBox(width: 8),
                        _dot(currentSheetPage == 1),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A7D91), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        onPressed: () async {
                          if (currentSheetPage == 0) {
                            sheetPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            await FirebaseFirestore.instance.collection('vehicles').add({
                              'uid': uid,
                              'nome': nomeController.text.trim().isEmpty ? "Nuovo Veicolo" : nomeController.text.trim(),
                              'cilindrata': cilindrataController.text.trim(),
                              'anno': annoController.text.trim(),
                              'carburante': selectedCarburante ?? "N/D",
                              'imageUrl': imageUrl,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text(currentSheetPage == 0 ? "Continua" : "Salva", style: const TextStyle(color: Colors.white)),
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

  // --- UI PRINCIPALE ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text("I tuoi veicoli", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vehicles').where('uid', isEqualTo: uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const Center(child: Text("Nessun veicolo"));

                  return Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _mainPageController,
                          // FORZA LO SCROLL ANCHE SE CI SONO CONFLITTI
                          physics: const AlwaysScrollableScrollPhysics(), 
                          onPageChanged: (index) => setState(() => _currentVehicleIndex = index),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var v = docs[index].data() as Map<String, dynamic>;
                            return Container(
                              // Questo Container serve a catturare il tocco su tutto lo schermo
                              width: MediaQuery.of(context).size.width,
                              height: double.infinity,
                              color: Colors.transparent, 
                              child: Center(
                                child: v['imageUrl'] != null 
                                  ? Image.network(v['imageUrl'], width: 300, fit: BoxFit.contain)
                                  : const Icon(Icons.directions_car, size: 120, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(docs.length, (index) => Container(
                          margin: const EdgeInsets.all(4),
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentVehicleIndex == index ? Colors.black : Colors.grey[400],
                          ),
                        )),
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
          backgroundColor: const Color(0xFF333333),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // Helper Widgets (Immagine, Info, Dot)
  Widget _buildStepImage(StateSetter setState, String? imageUrl, bool isUploading, VoidCallback onPick) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("Carica Foto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 200, width: 280,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
            child: isUploading ? const Center(child: CircularProgressIndicator()) : (imageUrl != null ? Image.network(imageUrl) : const Icon(Icons.image, size: 50)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepInfo(TextEditingController nome, TextEditingController cil, TextEditingController anno, TextEditingController note, String? carburante, Function(String?) onCarburanteChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 20),
          TextField(controller: nome, decoration: const InputDecoration(labelText: "Nome")),
          TextField(controller: cil, decoration: const InputDecoration(labelText: "Cilindrata")),
          TextField(controller: anno, decoration: const InputDecoration(labelText: "Anno")),
        ],
      ),
    );
  }

  Widget _dot(bool isActive) => AnimatedContainer(duration: const Duration(milliseconds: 200), width: isActive ? 20 : 8, height: 8, decoration: BoxDecoration(color: isActive ? Colors.black : Colors.grey, borderRadius: BorderRadius.circular(10)));
}