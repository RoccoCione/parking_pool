import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Necessario per il tema
import '../../main.dart'; // Assicurati che il percorso a ThemeService sia corretto
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

  final List<Widget> _pages = [
    const MapPage(),
    const VehiclesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ascoltiamo lo stato del tema globale
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    return Scaffold(
      // backgroundColor segue il tema globale per evitare "flash" bianchi durante i cambi pagina
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF1F3F4),
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, left: 25, right: 25),
      height: 75,
      decoration: BoxDecoration(
        // Colore dinamico: Grigio chiaro in light mode, Antracite in dark mode
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(35),
        border: isDark ? Border.all(color: Colors.white10, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.map_rounded, 0, isDark),
          _navItem(Icons.directions_car_filled, 1, isDark),
          _navItem(Icons.person_rounded, 2, isDark),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index, bool isDark) {
    bool isSelected = _selectedIndex == index;

    // Colore icona: Brand color se selezionata, altrimenti grigio adattivo
    Color iconColor;
    if (isSelected) {
      iconColor = const Color(0xFF4A7D91); // Il tuo colore brand
    } else {
      iconColor = isDark ? Colors.white38 : Colors.black45;
    }

    return IconButton(
      icon: Icon(icon, size: 30, color: iconColor),
      onPressed: () => setState(() => _selectedIndex = index),
    );
  }
}
