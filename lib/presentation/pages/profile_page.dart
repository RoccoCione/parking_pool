import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../environmental_calculator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _formatSafeNumber(dynamic value, int decimals) {
    if (value == null) return "0.${'0' * decimals}";

    if (value is num) return value.toStringAsFixed(decimals);

    if (value is String) {
      String cleanString = value.replaceAll(RegExp(r'[^0-9\.]'), '');
      double? parsed = double.tryParse(cleanString);
      return parsed?.toStringAsFixed(decimals) ?? "0.${'0' * decimals}";
    }

    return "0.${'0' * decimals}";
  }

  // --- FUNZIONE COME FUNZIONA ---
  void _showHowItWorksBottomSheet(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Icon(
                Icons.help_outline_rounded,
                size: 50,
                color: Color(0xFF4A7D91),
              ),
              const SizedBox(height: 15),
              Text(
                "Come funziona l'app",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 30),

              _buildInfoCard(
                isDark,
                Icons.location_on_rounded,
                "1. Stai uscendo?",
                "Premi il tasto 'Esco', seleziona l'area del campus in cui ti trovi e posiziona il marker nero sulla mappa. Gli altri utenti vedranno che stai per liberare un posto.",
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                isDark,
                Icons.local_parking_rounded,
                "2. Cerchi parcheggio?",
                "Esplora la mappa e cerca i pin blu 'P'. Cliccaci sopra per vedere i dettagli dell'utente che sta uscendo e chiedigli di scambiare il posto.",
              ),
              const SizedBox(height: 15),
              _buildInfoCard(
                isDark,
                Icons.handshake_rounded,
                "3. Lo Scambio",
                "Una volta accordati, parcheggia comodamente al suo posto. Contribuirai a ridurre il traffico e le emissioni nel nostro Campus!",
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7D91),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "HO CAPITO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- FUNZIONE INFORMAZIONI E IMPATTO ---
  void _showInfoBottomSheet(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              const Icon(
                Icons.auto_awesome,
                size: 50,
                color: Color(0xFF4A7D91),
              ),
              const SizedBox(height: 15),
              Text(
                "La nostra Missione",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 25),

              _buildSectionTitle("VISION"),
              Text(
                "Parking Pool nasce per risolvere il paradosso del traffico urbano: milioni di ore perse ogni anno alla ricerca di un posto auto che qualcuno ha appena lasciato libero. Trasformiamo la ricerca individuale in un gesto collettivo.",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7D91).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4A7D91).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "DATI DALLA RICERCA",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A7D91),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Il nostro algoritmo si basa sui risultati di un questionario somministrato a utenti reali, dal quale è emerso che il tempo medio speso alla ricerca di un parcheggio è di circa ${EnvironmentalCalculator.minutiDefaultCruising} minuti per sessione.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle("MODELLO AMBIENTALE"),
              _buildInfoCard(
                isDark,
                Icons.settings_suggest_outlined,
                "Algoritmo Dinamico",
                "Il calcolo analizza il consumo specifico per la tua motorizzazione e cilindrata.",
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                isDark,
                Icons.speed,
                "Cruising vs Idle",
                "Il sistema stima che durante la ricerca attiva del posto (Cruising) il consumo sia 2.5 volte superiore al minimo.",
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                isDark,
                Icons.cloud_outlined,
                "Coefficienti CO2",
                "Applichiamo standard di emissione certificati pesati in base all'anzianità (Classe Euro) del tuo veicolo.",
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7D91),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "CHIUDI",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4A7D91),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4A7D91), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNZIONE MODIFICA DATI ---
  void _showEditProfile(BuildContext context, Map<String, dynamic> userData) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final nomeController = TextEditingController(text: userData['nome']);
    final cognomeController = TextEditingController(text: userData['cognome']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Modifica Dati",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField("Nome", nomeController, false, isDark),
            const SizedBox(height: 15),
            _buildTextField("Cognome", cognomeController, false, isDark),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({
                        'nome': nomeController.text.trim(),
                        'cognome': cognomeController.text.trim(),
                      });
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  "Salva",
                  style: TextStyle(color: isDark ? Colors.black : Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- FUNZIONE CAMBIO PASSWORD ---
  void _showChangePassword(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cambia Password",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "Vecchia Password",
              oldPasswordController,
              true,
              isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Nuova Password",
              newPasswordController,
              true,
              isDark,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              "Conferma Nuova Password",
              confirmPasswordController,
              true,
              isDark,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Le password non coincidono"),
                      ),
                    );
                    return;
                  }
                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: oldPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPasswordController.text);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password aggiornata!")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Errore: ${e.toString()}")),
                    );
                  }
                },
                child: Text(
                  "Aggiorna Password",
                  style: TextStyle(color: isDark ? Colors.black : Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool obscure,
    bool isDark,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF1F3F4),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String username = userData['username'] ?? "Username";
          String nomeCognome =
              "${userData['nome'] ?? 'Nome'} ${userData['cognome'] ?? 'Cognome'}";

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 60),
            children: [
              Center(
                child: Text(
                  "Profilo",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionCard(
                isDark: isDark,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: isDark
                          ? Colors.white10
                          : const Color(0xFFF1F3F4),
                      child: Icon(
                        Icons.person_outline,
                        size: 45,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          nomeCognome,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "Impostazioni account",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildSectionCard(
                isDark: isDark,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildRowTile(
                      Icons.edit_outlined,
                      "Modifica dati personali",
                      isDark,
                      showDivider: true,
                      onTap: () => _showEditProfile(context, userData),
                    ),
                    _buildRowTile(
                      Icons.lock_outline,
                      "Cambio password",
                      isDark,
                      showDivider: true,
                      onTap: () => _showChangePassword(context),
                    ),
                    _buildSwitchRow(
                      Icons.dark_mode_outlined,
                      "Modalità oscura",
                      isDark,
                      isDark,
                      onChanged: (v) => themeService.toggleTheme(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "Il tuo impatto ambientale",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildSectionCard(
                isDark: isDark,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              "Posti ceduti",
                              userData['posti_ceduti']?.toString() ?? "0",
                              isDark,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFEEEEEE),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "Posti ricevuti",
                              userData['posti_ricevuti']?.toString() ?? "0",
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white10 : const Color(0xFFEEEEEE),
                    ),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          // UTILIZZO DELLA FUNZIONE SICURA QUI SOTTO:
                          Expanded(
                            child: _buildStatItem(
                              "Soldi risparmiati",
                              "€ ${_formatSafeNumber(userData['risparmio'], 2)}",
                              isDark,
                            ),
                          ),
                          VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFEEEEEE),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "CO2 risparmiata",
                              "${_formatSafeNumber(userData['co2_risparmiata'], 1)} kg",
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "Info e Supporto",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _buildSectionCard(
                isDark: isDark,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildRowTile(
                      Icons.help_outline_rounded,
                      "Come funziona",
                      isDark,
                      showDivider: true,
                      onTap: () => _showHowItWorksBottomSheet(context),
                    ),
                    _buildRowTile(
                      Icons.info_outline,
                      "Informazioni e Impatto",
                      isDark,
                      onTap: () => _showInfoBottomSheet(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              _buildLogoutButton(context),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS STRUTTURALI ---
  Widget _buildSectionCard({
    required Widget child,
    required bool isDark,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: isDark ? Border.all(color: Colors.white12) : null,
      ),
      child: child,
    );
  }

  Widget _buildRowTile(
    IconData icon,
    String title,
    bool isDark, {
    bool showDivider = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 55,
            endIndent: 20,
            color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
          ),
      ],
    );
  }

  Widget _buildSwitchRow(
    IconData icon,
    String title,
    bool value,
    bool isDark, {
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF4A7D91),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // Tasto Logout
  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        bool? confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Sei sicuro di voler uscire?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("ANNULLA"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("ESCI", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/auth',
              (route) => false,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFC35F53),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 15),
            Text(
              "Esci dall'account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
