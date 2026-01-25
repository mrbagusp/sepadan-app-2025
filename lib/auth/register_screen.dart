import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sepadan/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Buat Akun',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                        _showError('Email dan password tidak boleh kosong');
                        return;
                      }

                      setState(() => _isLoading = true);
                      try {
                        final user = await _authService.createUserWithEmailAndPassword(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                        if (user != null && mounted) {
                          context.go('/main');
                        }
                      } on FirebaseAuthException catch (e) {
                        _showError(e.message ?? 'Terjadi kesalahan pendaftaran');
                      } catch (e) {
                        _showError('Terjadi kesalahan tidak terduga: $e');
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Daftar', style: TextStyle(fontSize: 16)),
                  ),
                const SizedBox(height: 20),
                const Text('Atau', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    try {
                      final user = await _authService.signInWithGoogle();
                      if (user != null && mounted) {
                        context.go('/main');
                      }
                    } catch (e) {
                      _showError('Gagal masuk dengan Google');
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Masuk dengan Google'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    // TODO: Implement phone verification
                  },
                   style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Verifikasi Telepon'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
