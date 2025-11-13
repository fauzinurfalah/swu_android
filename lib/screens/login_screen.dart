import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:quickalert/quickalert.dart';
import 'package:project_mobileprog/screens/home_screen.dart';
import '../api/api_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> handleLogin() async {
    // Validate form
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Email dan Password harus diisi!',
      );
      return;
    }
    await doLogin();
  }

  Future<void> doLogin() async {
    setState(() {
      isLoading = true;
    });
    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    print(res);
    
    if (res.containsKey('error')) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: res['error'],
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (res['status'] == 200) {
      await ApiService.saveToken(res['data'], emailController.text);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Login Berhasil',
        onConfirmBtnTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        },
      );
    } else {
      final errorMessage = res['message'] ?? 'Email / Password Salah!';
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: errorMessage,
      );
    }
    setState(() {
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6292E1),
      body: Stack(
        children: [
          // Logo
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/swu.png',
                  height: 300, 
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(top: 150.0, left: 24.0, right: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                // Card Login
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Form(
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
                          // Input Email 
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
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
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Input Password 
                          TextFormField(
                            controller: passwordController,
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
                          
                          const SizedBox(height: 16),
                          // Tombol Login 
                          ElevatedButton(
                            onPressed: isLoading ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6292E1),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
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
                          // "Belum punya akun"
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
                                        Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const RegisterScreen()),
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
