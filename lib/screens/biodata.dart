import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:project_mobileprog/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_service.dart';

class Biodata extends StatefulWidget {
  const Biodata({super.key});

  @override
  State<Biodata> createState() => _BiodataState();
}

class _BiodataState extends State<Biodata> {
  Map<String, dynamic>? user;
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();

  // Controller biodata
  final namaC = TextEditingController();
  final jkC = TextEditingController();
  final tglC = TextEditingController();
  final alamatC = TextEditingController();
  final statusC = TextEditingController();

  // Gambar (support Web & Mobile)
  Uint8List? webImage;
  XFile? pickedFile;

  @override
  void initState() {
    super.initState();
    _getMahasiswaData();
  }

  Future<void> _getMahasiswaData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final email = prefs.getString('auth_email');

    Dio dio = Dio();
    dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await dio.post(
      "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
      data: {"email": email},
    );

    setState(() {
      user = response.data['data'];
      namaC.text = user?['nama'] ?? '';
      jkC.text = user?['jenis_kelamin'] ?? '';
      tglC.text = user?['tanggal_lahir'] ?? '';
      alamatC.text = user?['alamat'] ?? '';
      statusC.text = user?['status'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          webImage = bytes;
          pickedFile = image;
        });
        _uploadFotoWeb(bytes, image.name);
      } else {
        setState(() {
          pickedFile = image;
        });
        _uploadFotoMobile(image);
      }
    }
  }

  Future<void> _uploadFotoMobile(XFile image) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'nim': nim,
        'foto': await MultipartFile.fromFile(image.path),
      });

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/upload-foto-mahasiswa",
        data: formData,
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal upload foto: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadFotoWeb(Uint8List bytes, String filename) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final formData = FormData.fromMap({
        'nim': nim,
        'foto': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/upload-foto-mahasiswa",
        data: formData,
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal upload foto: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateBiodata() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final nim = user?['nim'];

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.put(
        "${ApiService.baseUrl}mahasiswa/update-mahasiswa",
        data: {
          "nim": nim,
          "nama": namaC.text,
          "jenis_kelamin": jkC.text,
          "tanggal_lahir": tglC.text,
          "alamat": alamatC.text,
          "status": statusC.text,
        },
      );

      if (response.data['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Biodata berhasil diperbarui!")),
        );
        _getMahasiswaData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update biodata: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ==== UI HELPERS ====
  Widget _buildEditableField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF212121),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(top: 4, bottom: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF2196F3),
                  width: 1.4,
                ),
              ),
            ),
            validator: label == "Nama"
                ? (v) => (v == null || v.isEmpty) ? "Nama wajib diisi" : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
          const Divider(
            color: Color(0xFFE0E0E0),
            height: 10,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = user?["foto"];
    final nim = user?["nim"] ?? "";
    final noTelp = user?["no_telp"] ?? "";
    final studi = user?["studi"] ?? ""; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP BAR (back + logo)
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black87,
                            ),
                            onPressed: () => 
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen()),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(
                                  "assets/images/swu.png",
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // AVATAR + CAMERA
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 28,
                                    offset: const Offset(0, 16),
                                    color: Colors.black.withOpacity(0.12),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: kIsWeb && webImage != null
                                    ? MemoryImage(webImage!)
                                    : pickedFile != null
                                        ? Image.network(pickedFile!.path).image
                                        : (fotoUrl != null && fotoUrl != "")
                                            ? NetworkImage(fotoUrl)
                                            : const AssetImage(
                                                    "assets/images/default_user.png")
                                                as ImageProvider,
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                        color:
                                            Colors.black.withOpacity(0.18),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // FIELDS 
                      _buildEditableField("Nama", namaC),
                      if (nim.isNotEmpty) _buildStaticField("NIM", nim),
                      if (studi.isNotEmpty) _buildStaticField("Studi", studi),
                      if (noTelp.isNotEmpty)
                        _buildStaticField("No. Telp", noTelp),
                      _buildEditableField("Tanggal Lahir", tglC),
                      _buildEditableField("Jenis Kelamin", jkC),
                      _buildEditableField("Alamat", alamatC),
                      _buildEditableField("Status", statusC),

                      const SizedBox(height: 28),

                      // TOMBOL 
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _updateBiodata,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isLoading
                              ? "Menyimpan..."
                              : "Simpan Perubahan",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
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
