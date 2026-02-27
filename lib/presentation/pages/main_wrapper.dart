import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'vehicles_page.dart';
import 'exit_parking_sheet.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // STATO PER LA SELEZIONE PARCHEGGIO
  bool _isSelectingLocation = false;

  final List<Widget> _pages = [
    const MapPage(),
    const VehiclesPage(),
    const ProfilePage(),
  ];

  // Funzione per aprire il BottomSheet finale
  void _openParkingDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExitParkingSheet(),
    );
  }

  // Funzione per annullare tutto e pulire la mappa
  void _cancelSelection() {
    setState(() {
      _isSelectingLocation = false;
    });
    final controller = MapPage.globalController;
    if (controller != null) {
      controller.runJavaScript("window.setSelectionMode(false)");
      controller.runJavaScript("window.removeParkingMarker()");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF1F3F4),
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),

          // PULSANTE DINAMICO (Appare solo su MapPage)
          if (_selectedIndex == 0)
            Positioned(
              bottom: 125,
              right: 25,
              left: _isSelectingLocation ? 25 : null,
              child: GestureDetector(
                onTap: () {
                  final controller = MapPage.globalController;
                  if (controller == null) return;

                  if (!_isSelectingLocation) {
                    // 1. Entra in modalità selezione
                    setState(() => _isSelectingLocation = true);
                    controller.runJavaScript("window.setSelectionMode(true)");

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Tocca la mappa per posizionare il marker",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // 2. Conferma la posizione e apri lo sheet
                    setState(() => _isSelectingLocation = false);
                    controller.runJavaScript("window.setSelectionMode(false)");
                    _openParkingDetails(); // Nome funzione corretto
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _isSelectingLocation
                        ? Colors.teal
                        : (isDark ? Colors.white : Colors.black),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSelectingLocation
                            ? Icons.check_circle
                            : Icons.directions_car,
                        color: _isSelectingLocation
                            ? Colors.white
                            : (isDark ? Colors.black : Colors.white),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isSelectingLocation ? "CONFERMA POSIZIONE" : "ESCO",
                        style: TextStyle(
                          color: _isSelectingLocation
                              ? Colors.white
                              : (isDark ? Colors.black : Colors.white),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tasto per annullare la selezione (X)
          if (_isSelectingLocation && _selectedIndex == 0)
            Positioned(
              bottom: 195,
              right: 25,
              child: FloatingActionButton.small(
                onPressed: _cancelSelection,
                backgroundColor: Colors.redAccent,
                elevation: 4,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30, left: 25, right: 25),
      height: 75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
    Color iconColor = isSelected
        ? const Color(0xFF4A7D91)
        : (isDark ? Colors.white38 : Colors.black45);

    return IconButton(
      icon: Icon(icon, size: 30, color: iconColor),
      onPressed: () {
        if (_selectedIndex != index) {
          _cancelSelection(); // Se cambi pagina, pulisce marker e selezione
          setState(() {
            _selectedIndex = index;
          });
        }
      },
    );
  }
}
