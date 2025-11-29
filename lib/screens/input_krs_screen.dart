import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import 'krs_detail_page.dart';

class InputKrsScreen extends StatefulWidget {
  const InputKrsScreen({Key? key}) : super(key: key);

  @override
  State<InputKrsScreen> createState() => _InputKrsScreenState();
}

class _InputKrsScreenState extends State<InputKrsScreen> {
  Map<String, dynamic>? user;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController semesterController = TextEditingController();

  bool isLoading = false; // untuk submit
  bool isFetching = true; // untuk seluruh data awal
  bool isFetchingKrs = false;

  List<dynamic> daftarKrs = [];

  // minimal semester yang boleh diinput (diisi dari prefs saat load atau dari user profile)
  int _minSemester = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // baca semester yang tersimpan dari login dulu (jika ada)
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('semester');
    if (stored != null) {
      final v = int.tryParse(stored);
      if (v != null) _minSemester = v;
    }

    // mobprg
    await _getMahasiswaData();
    if (user != null) {
      // pastikan min semester diperbarui dari profile yang baru di-fetch
      final s = user?['semester'];
      final v = s is int ? s : int.tryParse(s?.toString() ?? '');
      if (v != null) _minSemester = v;
      await _getDaftarKrs();
    } else {
      await _getDaftarKrs();
    }

    setState(() => isFetching = false);
  }

  Future<void> _getMahasiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final email = prefs.getString('auth_email');

      Dio dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );

      setState(() {
        user = response.data['data'];
        // simpan semester jika ada dan update min semester
        if (user?['semester'] != null) {
          prefs.setString('semester', user!['semester'].toString());
          final v = user!['semester'] is int
              ? user!['semester'] as int
              : int.tryParse(user!['semester'].toString());
          if (v != null) _minSemester = v;
        }
      });
    } catch (e) {
      debugPrint("ERROR GET USER: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat data mahasiswa"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitKrs() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.post(
        "${ApiService.baseUrl}krs/buat-krs",
        data: {'nim': user?['nim'], 'semester': semesterController.text},
      );

      final msg = response.data['message'] ?? "KRS berhasil disimpan";

      if (response.statusCode == 201 ||
          response.statusCode == 202 ||
          response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );

        semesterController.clear();
        _formKey.currentState!.reset();

        await _getDaftarKrs();
      } else {
        final err = response.data is Map
            ? (response.data['message'] ?? response.data.toString())
            : response.data.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan KRS: $err'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.response?.data['message'] ?? "Gagal menyimpan data"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getDaftarKrs() async {
    if (user == null) return;

    setState(() => isFetchingKrs = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      Dio dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.get(
        "${ApiService.baseUrl}krs/daftar-krs?id_mahasiswa=${user!['nim']}",
      );

      if (response.statusCode == 200) {
        setState(() {
          daftarKrs = response.data['data'] ?? [];
        });
      } else {
        setState(() => daftarKrs = []);
      }
    } catch (e) {
      debugPrint("ERROR GET KRS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memuat daftar KRS"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isFetchingKrs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minSemester = _minSemester;
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            // Header biru dengan back dan logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF7BA7E2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Input KRS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // logo kanan atas
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/swu.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Area putih melengkung oke gas
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: isFetching
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          const Text(
                            'Input semester untuk membuat KRS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Form semester + tombol simpan
                          Form(
                            key: _formKey,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: semesterController,
                                    decoration: InputDecoration(
                                      labelText: "Semester",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return "Semester wajib diisi";
                                      final v = int.tryParse(value);
                                      if (v == null)
                                        return "Masukkan nomor semester yang valid";
                                      if (v < minSemester)
                                        return "Semester minimal adalah $minSemester";
                                      if (v > 16)
                                        return "Maksimal semester adalah 16";
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _submitKrs,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                        1000,
                                        123,
                                        167,
                                        226,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save),
                                    label: Text(
                                      isLoading ? 'Menyimpan' : 'Simpan',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Judul daftar KRS
                          Text(
                            "Daftar KRS Mahasiswa",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Konten daftar KRS
                          Expanded(
                            child: isFetchingKrs
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : daftarKrs.isEmpty
                                ? const Center(
                                    child: Text("Belum ada data KRS."),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    itemCount: daftarKrs.length,
                                    itemBuilder: (context, index) {
                                      final krs = daftarKrs[index];
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.book,
                                            color: Color.fromARGB(
                                              1000,
                                              123,
                                              167,
                                              226,
                                            ),
                                          ),
                                          title: const Text(
                                            "KRS Anda",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            "Semester: ${krs['semester']} | Tahun: ${krs['tahun_ajaran'] ?? krs['tahun'] ?? '-'}",
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => KrsDetailPage(
                                                  idKrs: krs['id'],
                                                  semester:
                                                      krs['semester']
                                                          ?.toString() ??
                                                      "-",
                                                  tahunAjaran:
                                                      krs['tahun_ajaran']
                                                          ?.toString() ??
                                                      krs['tahun']
                                                          ?.toString() ??
                                                      "-",
                                                ),
                                              ),
                                            ).then((_) => _getDaftarKrs());
                                          },
                                          // hapus icon delete sesuai permintaan; hanya panah lanjut
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 18,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
