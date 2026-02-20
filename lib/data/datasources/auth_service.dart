import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Verifica in tempo reale se lo username è disponibile
  Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().length < 3) return true;

    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      // STAMPA L'ERRORE NEL TERMINALE
      print("ERRORE FIRESTORE USERNAME: $e");
      // Se c'è un errore, permettiamo comunque di procedere per non bloccare l'utente
      // o gestiamo il messaggio di errore nella UI.
      return true;
    }
  }

  /// Registrazione usando Username con creazione di email tecnica
  Future<User?> registerUser({
    required String username,
    required String password,
    required String nome,
    required String cognome,
    required String status,
  }) async {
    // Generiamo l'email tecnica univoca
    String emailTecnica = "${username.trim().toLowerCase()}@parkingpool.it";

    // 1. Creazione utente su Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: emailTecnica,
      password: password,
    );

    User? user = result.user;

    // 2. Salvataggio profilo esteso su Firestore
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'username': username.trim(),
        'nome': nome.trim(),
        'cognome': cognome.trim(),
        'status': status,
        'email': emailTecnica,
        'createdAt': FieldValue.serverTimestamp(),
        // INIZIALIZZA LE STATISTICHE
        'posti_ceduti': 0,
        'posti_ricevuti': 0,
        'risparmio': "0€",
        'tempo': "0 min",
      });
    }
    return user;
  }

  /// Login usando Username tramite recupero email tecnica da Firestore
  Future<User?> loginUser(String username, String password) async {
    // 1. Cerchiamo l'email tecnica associata allo username
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw "Username non trovato";
    }

    String emailTecnica = query.docs.first.get('email');

    // 2. Eseguiamo il login con le credenziali trovate
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: emailTecnica,
      password: password,
    );

    return result.user;
  }

  Future<void> signOut() async => await _auth.signOut();
}
