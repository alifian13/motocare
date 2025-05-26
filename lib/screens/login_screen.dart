// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'register_screen.dart'; // <-- TAMBAHKAN IMPOR INI
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _userService.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Arahkan ke HomeScreen menggunakan routeName jika ada
        Navigator.pushNamedAndRemoveUntil(context, HomeScreen.routeName, (route) => false); // Pastikan HomeScreen punya routeName
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Login gagal. Silakan coba lagi.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login MotoCare'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Tidak ada tombol kembali, sudah benar
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.two_wheeler,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Selamat Datang Kembali!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan masuk untuk melanjutkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan alamat email Anda',
                    prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Masukkan format email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Masukkan password Anda',
                    prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    // Validasi panjang password bisa disesuaikan dengan backend jika perlu
                    // if (value.length < 6) {
                    //   return 'Password minimal 6 karakter';
                    // }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, // Tambahkan warna primary
                          foregroundColor: Colors.white, // Warna teks putih
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Style teks
                        ),
                        onPressed: _attemptLogin, // Memanggil fungsi _attemptLogin
                        child: const Text('LOGIN'),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun?',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        // Pastikan '/register' adalah routeName yang benar untuk RegisterScreen
                        Navigator.pushNamed(context, RegisterScreen.routeName);
                      },
                      child: Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} // Kurung kurawal penutup ekstra telah dihapus dari sini