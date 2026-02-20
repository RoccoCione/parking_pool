import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Funzione per il cambio password tramite Firebase
  void _showChangePassword(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        // Necessario per l'indicatore di caricamento dentro il bottom sheet
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
              const Text(
                "Cambia Password",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Vecchia Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Nuova Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Conferma Nuova Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Le nuove password non coincidono",
                                ),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isLoading = true);

                          try {
                            User? user = FirebaseAuth.instance.currentUser;

                            // 1. Ri-autenticazione necessaria per Firebase
                            AuthCredential credential =
                                EmailAuthProvider.credential(
                                  email: user!.email!,
                                  password: oldPasswordController.text,
                                );

                            await user.reauthenticateWithCredential(credential);

                            // 2. Aggiornamento Password
                            await user.updatePassword(
                              newPasswordController.text,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Password aggiornata con successo!",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Errore: Password errata o troppo debole",
                                ),
                              ),
                            );
                          } finally {
                            setModalState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Aggiorna Password",
                          style: TextStyle(color: Colors.white),
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

  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superiore per indicare che si può trascinare giù
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Icon(Icons.info_outline, size: 50, color: Color(0xFF4A7D91)),
            const SizedBox(height: 15),
            const Text(
              "Cos'è Parking Pool?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Parking Pool è un'iniziativa nata per semplificare la ricerca del parcheggio all'interno della nostra comunità. \n\n"
              "L'obiettivo è creare una rete collaborativa tra studenti, docenti e personale: chi sta per lasciare un posto auto può segnalarlo in tempo reale, permettendo a chi arriva di trovarlo senza stress. \n\n"
              "Meno tempo a girare a vuoto significa meno traffico, meno inquinamento e più tempo per le lezioni!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Ho capito",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Funzione per la modifica del profilo (Nome e Cognome)
  void _showEditProfile(BuildContext context, Map<String, dynamic> userData) {
    final nomeController = TextEditingController(text: userData['nome']);
    final cognomeController = TextEditingController(text: userData['cognome']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const Text(
              "Modifica Dati",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: cognomeController,
              decoration: const InputDecoration(
                labelText: "Cognome",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
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
                    setState(() {}); // Ricarica per vedere i nuovi dati
                  }
                },
                child: const Text(
                  "Salva",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
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
              const Center(
                child: Text(
                  "Profilo",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 1. Card Header Utente
              _buildSectionCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFFF1F3F4),
                      child: Icon(
                        Icons.person_outline,
                        size: 45,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
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

              // 2. Gruppo Impostazioni
              _buildSectionCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildRowTile(
                      Icons.edit_outlined,
                      "Modifica dati personali",
                      showDivider: true,
                      onTap: () => _showEditProfile(context, userData),
                    ),
                    _buildRowTile(
                      Icons.lock_outline,
                      "Cambio password",
                      showDivider: true,
                      onTap: () => _showChangePassword(context),
                    ),
                    _buildSwitchRow(
                      Icons.notifications_none,
                      "Notifiche",
                      true,
                      showDivider: true,
                    ),
                    _buildSwitchRow(
                      Icons.dark_mode_outlined,
                      "Modalità oscura",
                      false,
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

              // 3. Griglia Statistiche
              _buildSectionCard(
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
                            ),
                          ),
                          const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "Posti ricevuti",
                              userData['posti_ricevuti']?.toString() ?? "0",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              "Soldi risparmiati",
                              "${userData['risparmio']?.toString() ?? "0"}",
                            ),
                          ),
                          const VerticalDivider(
                            width: 1,
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              "Tempo risparmiato",
                              "${userData['tempo']?.toString() ?? "0"}",
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
                padding: EdgeInsets.zero,
                child: _buildRowTile(
                  Icons.info_outline,
                  "Informazioni",
                  onTap: () =>
                      _showInfoBottomSheet(context), // Collega qui la funzione
                ),
              ),

              const SizedBox(height: 15),

              // 4. Logout Button
              _buildLogoutButton(context),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Conferma Logout"),
            content: const Text("Sei sicuro di voler uscire dal tuo account?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Annulla",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/auth', (route) => false);
                  }
                },
                child: const Text(
                  "Esci",
                  style: TextStyle(
                    color: Color(0xFFC35F53),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSwitchRow(
    IconData icon,
    String title,
    bool value, {
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: value,
                onChanged: (v) {},
                activeColor: const Color(0xFF4A6572),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 55,
            endIndent: 20,
            color: Color(0xFFF1F3F4),
          ),
      ],
    );
  }

  Widget _buildRowTile(
    IconData icon,
    String title, {
    bool showDivider = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(icon, color: Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 55,
            endIndent: 20,
            color: Color(0xFFF1F3F4),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
