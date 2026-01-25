import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Email dan password tidak boleh kosong');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (user != null && mounted) context.go('/main');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login gagal: ${e.code}');
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) context.go('/main');
    } catch (e) {
      _showError('Gagal masuk dengan Google. Pastikan SHA-1 sudah terdaftar.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !phone.startsWith('+')) {
      _showError('Masukkan nomor telepon dengan kode negara (contoh: +62812...)');
      return;
    }

    setState(() => _isLoading = true);
    await _authService.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        final user = await FirebaseAuth.instance.signInWithCredential(credential);
        if (user.user != null && mounted) context.go('/main');
      },
      verificationFailed: (e) {
        setState(() => _isLoading = false);
        _showError('Verifikasi gagal: ${e.message}');
      },
      codeSent: (id, resendToken) {
        setState(() {
          _isLoading = false;
          _isOtpSent = true;
          _verificationId = id;
        });
      },
      codeAutoRetrievalTimeout: (id) => _verificationId = id,
    );
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithPhoneNumber(_verificationId!, _otpController.text.trim());
      if (user != null && mounted) context.go('/main');
    } catch (e) {
      _showError('OTP Salah atau Expired');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                const Text('SEPADAN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 40),
                
                // --- EMAIL LOGIN ---
                _buildTextField(_emailController, 'Email', Icons.email),
                const SizedBox(height: 15),
                _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
                const SizedBox(height: 20),
                _buildButton('Masuk dengan Email', _loginWithEmail),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('--- ATAU ---', style: TextStyle(color: Colors.white70)),
                ),

                // --- PHONE LOGIN ---
                if (!_isOtpSent) ...[
                  _buildTextField(_phoneController, 'Nomor Telepon (+62...)', Icons.phone),
                  const SizedBox(height: 10),
                  _buildButton('Kirim OTP via SMS', _sendOtp, color: Colors.green),
                ] else ...[
                  _buildTextField(_otpController, 'Masukkan 6 Digit OTP', Icons.sms),
                  const SizedBox(height: 10),
                  _buildButton('Verifikasi OTP', _verifyOtp, color: Colors.orange),
                ],

                const SizedBox(height: 20),
                _buildButton('Masuk dengan Google', _loginWithGoogle, color: Colors.white, textColor: Colors.black),
                
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Belum punya akun? Daftar', style: TextStyle(color: Colors.white)),
                ),
                if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color, Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.deepPurpleAccent,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text),
      ),
    );
  }
}
