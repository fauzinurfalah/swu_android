import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
import 'package:iconsax/iconsax.dart';
import '../api/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterPagesScreen();
}

class _RegisterPagesScreen extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tglLahirController = TextEditingController();
  String? _jenisKelamin;
  final _alamat = TextEditingController();
  final _angkatan = TextEditingController();
  final _id_tahun = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isconfirmPasswordVisible = false;

  void _registerAct() async {
    if (_formKey.currentState!.validate()) {
      final nama = _nameController.text;
      final tglLahir = _tglLahirController.text;
      final jenisKelamin = _jenisKelamin;
      final alamat = _alamat.text;
      final angkatan = _angkatan.text;
      final id_tahun = _id_tahun.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      try {
        final dio = Dio();
        final response = await dio.post(
          '${ApiService.baseUrl}auth/register',
          data: {
            'nama': nama,
            'tgl_lahir': tglLahir,
            'jenis_kelamin': jenisKelamin,
            'alamat': alamat,
            'angkatan': angkatan,
            'id_tahun': id_tahun,
            'email': email,
            'password': password,
          },
        );
        if (response.data['status'] == 200) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'Registrasi Berhasil',
            onConfirmBtnTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal registrasi: $e")),
        );
        return;
      }
    }
  }

  Future<void> _pilihTanggal() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1999),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tglLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grayFill = const Color(0xFFF1F1F1);
    final labelStyle = const TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFF9A9A9A),
    );

    InputDecoration _pillDec({
      required String label,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: labelStyle,
        filled: true,
        fillColor: grayFill,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(icon, color: Colors.black54),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: suffixIcon,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF6292E1),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Opacity(
                opacity: 0.20,
                child: Image.asset('assets/images/swu.png', height: 320),
              ),
            ),
          ),
          Positioned.fill(
            top: 140,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // back row
                        Row(
                          children: [
                            IconButton(
                              padding: const EdgeInsets.only(right: 8),
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Kembali ke halaman login",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Daftar Akun",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: ListView(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              children: [
                                // Nama
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _pillDec(
                                    label: "Nama",
                                    icon: Iconsax.user,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Name tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Tgl Lahir
                                TextFormField(
                                  controller: _tglLahirController,
                                  readOnly: true,
                                  onTap: _pilihTanggal,
                                  decoration: _pillDec(
                                    label: "Tanggal Lahir",
                                    icon: Iconsax.calendar,
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Iconsax.calendar),
                                    ),
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Tanggal lahir wajib diisi"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Jenis Kelamin
                                DropdownButtonFormField<String>(
                                  value: _jenisKelamin,
                                  decoration: _pillDec(
                                    label: "Jenis Kelamin",
                                    icon: Iconsax.user_tag,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: "L",
                                        child: Text("Laki-laki")),
                                    DropdownMenuItem(
                                        value: "P",
                                        child: Text("Perempuan")),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _jenisKelamin = v),
                                  validator: (v) =>
                                      v == null ? "Pilih jenis kelamin" : null,
                                ),
                                const SizedBox(height: 12),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _pillDec(
                                    label: "Email",
                                    icon: Iconsax.sms,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Email tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Alamat
                                TextFormField(
                                  controller: _alamat,
                                  decoration: _pillDec(
                                    label: "Alamat",
                                    icon: Iconsax.location,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "alamat tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Angkatan
                                TextFormField(
                                  controller: _angkatan,
                                  decoration: _pillDec(
                                    label: "Angkatan",
                                    icon: Iconsax.tag,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Angkatan tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Tahun Masuk
                                TextFormField(
                                  controller: _id_tahun,
                                  decoration: _pillDec(
                                    label: "Tahun Masuk",
                                    icon: Iconsax.calendar_2,
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Tahun Masuk tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: _pillDec(
                                    label: "Password",
                                    icon: Iconsax.lock,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible),
                                      icon: Icon(_isPasswordVisible
                                          ? Iconsax.eye_slash
                                          : Iconsax.eye),
                                    ),
                                  ),
                                  validator: (v) => v!.isEmpty
                                      ? "Password tidak boleh kosong"
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // Konfirmasi Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isconfirmPasswordVisible,
                                  decoration: _pillDec(
                                    label: "Konfirmasi Password",
                                    icon: Iconsax.lock,
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() =>
                                          _isconfirmPasswordVisible =
                                              !_isconfirmPasswordVisible),
                                      icon: Icon(_isconfirmPasswordVisible
                                          ? Iconsax.eye_slash
                                          : Iconsax.eye),
                                    ),
                                  ),
                                  validator: (v) =>
                                      v != _passwordController.text
                                          ? "Password tidak sesuai"
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // Button daftar
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _registerAct,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: const StadiumBorder(),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            "Daftarkan Akun Saya",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Footer
                                Column(
                                  children: const [
                                    Text(
                                      "“Semoga ga nyesel masuk SWU”",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF9A9A9A),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "swu.ac.id",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFB7B7B7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }
}
