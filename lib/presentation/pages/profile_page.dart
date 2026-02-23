import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- FUNZIONE INFORMAZIONI RIPRISTINATA E ADATTATA AL TEMA ---
  void _showInfoBottomSheet(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Icon(Icons.info_outline, size: 50, color: Color(0xFF4A7D91)),
            const SizedBox(height: 15),
            Text(
              "Cos'è Parking Pool?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Parking Pool è un'iniziativa nata per semplificare la ricerca del parcheggio all'interno della nostra comunità. \n\n"
              "L'obiettivo è creare una rete collaborativa tra studenti, docenti e personale: chi sta per lasciare un posto auto può segnalarlo in tempo reale, permettendo a chi arriva di trovarlo senza stress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Ho capito",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF4A7D91),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
                  if (mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
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

  void _showChangePassword(BuildContext context) {
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  onPressed: isLoading
                      ? null
                      : () async {
                          /* Logica Firebase... */
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          "Aggiorna Password",
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                          ),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
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
                      Icons.notifications_none,
                      "Notifiche",
                      true,
                      isDark,
                      showDivider: true,
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
                "Dati dell'applicazione",
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
                          Expanded(
                            child: _buildStatItem(
                              "Soldi risparmiati",
                              "€${userData['risparmio'] ?? '0'}",
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
                              "Tempo risparmiato",
                              "${userData['tempo'] ?? '0'}m",
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              _buildSectionCard(
                isDark: isDark,
                padding: EdgeInsets.zero,
                child: _buildRowTile(
                  Icons.info_outline,
                  "Informazioni",
                  isDark,
                  onTap: () => _showInfoBottomSheet(context), // COLLEGATO!
                ),
              ),

              const SizedBox(height: 15),
              _buildLogoutButton(context),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---
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
    bool showDivider = false,
    Function(bool)? onChanged,
  }) {
    return Column(
      children: [
        Padding(
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
                activeColor: const Color(0xFF4A7D91),
              ),
            ],
          ),
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

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFC35F53),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_remove_outlined, color: Colors.white),
          SizedBox(width: 15),
          Text(
            "Logout",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Spacer(),
          Icon(Icons.logout, color: Colors.white),
        ],
      ),
    );
  }
}
