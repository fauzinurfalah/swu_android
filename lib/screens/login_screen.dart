import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String nim = _nimController.text;
    String password = _passwordController.text;

    // Simulasi proses login (ganti dengan API call sesungguhnya)
    await Future.delayed(const Duration(seconds: 2));

    // Contoh validasi sederhana (ganti dengan validasi dari backend)
    if (nim == "123456" && password == "password") {
      // Login berhasil, navigasi ke home screen
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {
            'nim': nim,
            'nama': 'Mahasiswa Demo', // Data dari API
          },
        );
      }
    } else {
      // Login gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NIM atau Password salah!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
     // Pastikan untuk menghentikan loading state setelah selesai
    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Mengubah background menjadi warna solid biru sesuai gambar
      backgroundColor: const Color(0xFF6292E1),
      body: Stack(
        children: [
          // 2. Menyesuaikan posisi dan opacity logo background
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  // Pastikan path asset logo Anda benar
                  'assets/images/swu.png',
                  height: 300, // Logo diperbesar
                ),
              ),
            ),
          ),
          // Mengatur agar semua konten berada dalam area aman (safe area)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mengubah posisi header
                Padding(
                  padding: const EdgeInsets.only(top: 150.0, left: 24.0, right: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3. Header Text
                        const Text(
                          'Halo!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selamat datang kembali',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 4. Card Login
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    // Membuat sudut card lebih melengkung
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 5. Input NIM dengan style baru
                          TextFormField(
                            controller: _nimController,
                            decoration: InputDecoration(
                              hintText: 'NIM',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                // Membuat input field lebih melengkung (pill shape)
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'NIM harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // 6. Input Password dengan style baru
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Lupa Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fitur lupa password'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Lupa password ya?',
                                style: TextStyle(
                                  color: Color(0xFF6292E1),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 7. Tombol Login dengan style baru
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6292E1),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
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
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 24),
                          // 8. Menambahkan teks "Belum punya akun"
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(text: 'Belum punya akun juga? '),
                                  TextSpan(
                                    text: 'Bikin akun dulu',
                                    style: const TextStyle(
                                      color: Color(0xFF6292E1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        // Aksi ketika teks di tap, contoh: navigasi ke halaman registrasi
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Navigasi ke halaman registrasi'),
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
