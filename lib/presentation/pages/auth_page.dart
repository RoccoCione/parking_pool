import 'package:flutter/material.dart';
import 'package:parking_pool/presentation/pages/main_wrapper.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/custom_text_field.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();

  String _selectedStatus = 'Studente';
  bool _isLogin = true;
  bool _isLoading = false;

  // Variabili per la validazione in tempo reale
  bool _usernameAvailable = true;
  bool _isCheckingUsername = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Listener per il controllo username in tempo reale
    _usernameController.addListener(_checkUsernameAvailability);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    super.dispose();
  }

  void _checkUsernameAvailability() async {
    String currentText = _usernameController.text.trim();

    // Controlla solo se ci sono almeno 3 caratteri
    if (_isLogin || currentText.length < 3) {
      setState(() => _usernameAvailable = true);
      return;
    }

    setState(() => _isCheckingUsername = true);

    final isAvailable = await _authService.isUsernameAvailable(currentText);

    if (mounted) {
      setState(() {
        _usernameAvailable = isAvailable;
        _isCheckingUsername = false;
      });
    }
  }

  bool _isPasswordValid(String password) {
    // Almeno 8 caratteri, una maiuscola, una minuscola e un numero
    final passwordRegExp = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _submit() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Inserisci username e password");
      return;
    }

    setState(() => _isLoading = true);
    print("Inizio processo di ${_isLogin ? 'Login' : 'Registrazione'}...");

    try {
      if (_isLogin) {
        await _authService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
        print("Login effettuato con successo!");
      } else {
        await _authService.registerUser(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          nome: _nomeController.text.trim(),
          cognome: _cognomeController.text.trim(),
          status: _selectedStatus,
        );
        print("Registrazione completata e dati salvati su Firestore!");
      }

      // IL PUNTO CRITICO: La navigazione
      if (mounted) {
        print("Navigazione verso MainWrapper...");
        // Proviamo la navigazione diretta se la rotta nominata fallisce
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      print("ERRORE DURANTE L'AUTH: $e");
      _showSnackBar("Errore: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo.png', width: 150),
              const Spacer(),

              Flexible(
                flex: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      label: 'Username',
                      hint: 'Il tuo username',
                      controller: _usernameController,
                    ),
                    // Indicatore disponibilità username
                    if (!_isLogin && _usernameController.text.length >= 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: _isCheckingUsername
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _usernameAvailable
                                    ? "✓ Disponibile"
                                    : "✗ Già occupato",
                                style: TextStyle(
                                  color: _usernameAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                      ),

                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Nome',
                        hint: 'Il tuo nome',
                        controller: _nomeController,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Cognome',
                        hint: 'Il tuo cognome',
                        controller: _cognomeController,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusDropdown(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Accedi' : 'Registrati',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              _buildAuthSwitcher(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // I metodi _buildStatusDropdown e _buildAuthSwitcher rimangono uguali a prima
  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              items: ['Studente', 'Docente', 'Personale'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedStatus = newValue!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthSwitcher() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Accedi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Registrati',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
