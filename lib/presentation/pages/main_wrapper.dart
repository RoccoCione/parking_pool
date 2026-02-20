import 'package:flutter/material.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'vehicles_page.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // 1. Sistemiamo la lista delle pagine nell'ordine corretto
  final List<Widget> _pages = [
    const MapPage(),      // Indice 0
    const VehiclesPage(), // Indice 1 (Sostituito il Text statico con la vera pagina)
    const ProfilePage(),  // Indice 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Fondamentale per vedere la mappa sotto la barra
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, left: 25, right: 25),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4), // Colore grigio chiaro come da tuo stile
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 2. Sistemiamo l'ordine delle icone per matchare le pagine
          _navItem(Icons.home_filled, 0),    // Home/Map
          _navItem(Icons.directions_car, 1), // Veicoli
          _navItem(Icons.person, 2),         // Profilo
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        size: 32,
        color: isSelected ? const Color(0xFF4A6572) : Colors.black45,
      ),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}