import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';
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
  bool _isObscure = true;

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
      final confirmPassword = _confirmPasswordController.text;

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
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal registrasi: $e")));
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
    return Scaffold(
      appBar: AppBar(title: Text("Register Pages")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // form input nama
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Name tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // form input tanggal lahir
              TextFormField(
                controller: _tglLahirController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Tanggal Lahir",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: _pilihTanggal,
                validator: (v) =>
                    v!.isEmpty ? "Tanggal lahir wajib diisi" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Jenis Kelamin
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Jenis Kelamin"),
                value: _jenisKelamin,
                items: const [
                  DropdownMenuItem(value: "L", child: Text("Laki-laki")),
                  DropdownMenuItem(value: "P", child: Text("Perempuan")),
                ],
                onChanged: (value) => setState(() => _jenisKelamin = value),
                validator: (v) => v == null ? "Pilih jenis kelamin" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Form Input Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Form Input Alamat
              TextFormField(
                controller: _alamat,
                decoration: const InputDecoration(
                  labelText: "Alamat",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "alamat tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Form Inputan Angkatan
              TextFormField(
                controller: _angkatan,
                decoration: const InputDecoration(
                  labelText: "Angkatan",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Angkatan tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Form Input Tahun Masuk
              TextFormField(
                controller: _id_tahun,
                decoration: const InputDecoration(
                  labelText: "Tahun Masuk",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Tahun Masuk tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // Form Input Passowrd
              TextFormField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _isObscure = !_isObscure);
                    },
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Password tidak boleh kosong" : null,
              ),
              // spasi / jarak
              const SizedBox(height: 16),
              // form confirmation password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _isObscure = !_isObscure);
                    },
                  ),
                ),
                validator: (value) => value != _passwordController.text
                    ? "Password tidak sesuai"
                    : null,
              ),
              // spasi / jarak
              const SizedBox(height: 32),
              // Button Aksi untuk register
              ElevatedButton(
                onPressed: _registerAct,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
