import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_wrapper.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Solo i 3 passaggi fondamentali per la versione base
  final List<Map<String, dynamic>> _steps = [
    {
      "title": "Benvenuto in Parking Pool",
      "desc":
          "La rete per scambiare parcheggi nel campus in modo semplice e veloce.",
      "icon": Icons.directions_car_rounded,
    },
    {
      "title": "Stai uscendo?",
      "desc":
          "Seleziona il tuo veicolo, segna la tua posizione sulla mappa e attendi un compagno di scambio.",
      "icon": Icons.location_on_rounded,
    },
    {
      "title": "Cerchi parcheggio?",
      "desc":
          "Guarda i pin sulla mappa. Sono studenti e professori pronti a cederti il posto in tempo reale!",
      "icon": Icons.local_parking_rounded,
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final Color brandColor = const Color(0xFF4A7D91);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header con pulsante Salta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      _currentPage == _steps.length - 1 ? "" : "Salta",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corpo Centrale (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _steps.length,
                itemBuilder: (context, index) =>
                    _buildStep(_steps[index], isDark, brandColor),
              ),
            ),

            // Footer
            _buildFooter(isDark, brandColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(Map<String, dynamic> step, bool isDark, Color brandColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Grafica "Hero"
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(step['icon'], size: 90, color: brandColor),
            ),
          ),
          const SizedBox(height: 50),

          // Titolo
          Text(
            step['title']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Descrizione
          Text(
            step['desc']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, Color brandColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Indicatori di pagina (Dots) al CENTRO
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 8,
                width: _currentPage == index ? 30 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.white24 : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Pulsante Avanti / Inizia CENTRATO
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              key: ValueKey<int>(_currentPage),
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: _currentPage == _steps.length - 1 ? 40 : 35,
                  vertical: 16,
                ),
                elevation: 5,
                shadowColor: brandColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                if (_currentPage == _steps.length - 1) {
                  _completeOnboarding();
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == _steps.length - 1 ? "INIZIA ORA" : "AVANTI",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (_currentPage != _steps.length - 1) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
