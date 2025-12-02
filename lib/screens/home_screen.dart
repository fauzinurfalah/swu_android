import 'package:flutter/material.dart';
import 'package:project_mobileprog/screens/faq_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'biodata.dart';
import 'jadwal_screen.dart';
import 'input_krs_screen.dart';
import 'transkip.dart';
import 'sp_screen.dart';
import 'khs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _getMahasiswaData();
  }

  Future<void> _getMahasiswaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final email = prefs.getString("auth_email");

      Dio dio = Dio();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
      dio.options.headers['Content-type'] = 'application/json';

      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );

      setState(() {
        user = response.data["data"];
      });
    } catch (e) {
      print("Error getMahasiswa: $e");
    }
  }

  // Helper untuk mendapatkan nilai semester saat ini
  // 🟢 ASUMSI: Jika data API Anda tidak memiliki field 'semester', 
  // Anda bisa menghitungnya dari angkatan dan tahun/bulan saat ini.
  // Untuk saat ini, kita akan menggunakan nilai statis 5 jika field 'semester' 
  // tidak ada di data 'user', atau Anda bisa menambahkannya ke data user jika tersedia.
  int _getCurrentSemester() {
    // ⚠️ Ganti logika ini jika Anda memiliki data semester yang lebih akurat dari API.
    return user?['semester'] ?? 5; // Menggunakan 5 sebagai default/contoh
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 Pastikan user data sudah dimuat sebelum mengaksesnya, atau gunakan nilai default.
    final currentNama = user?["nama"] ?? "Nama Mahasiswa";
    final currentNim = user?["nim"] ?? "A00.0000.0000";
    final currentSemester = _getCurrentSemester();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: const BottomNav(initialIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildBlueHeader(),

              const SizedBox(height: 24),

              // ====== CARD ABSENSI ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JadwalPage()),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // TEXT DI KIRI ATAS
                        Positioned(
                          left: 20,
                          top: 18,
                          child: Text(
                            "Absensi",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // ICON PNG DI KANAN TENGAH
                        Positioned(
                          right: 20,
                          top: 28,
                          child: const Icon(
                            Icons.people_alt_outlined,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 26),

              // ====== GRID MENU ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 26,
                  crossAxisSpacing: 26,
                  childAspectRatio: 0.9,
                  children: [
                    _menuItem(
                      'assets/icons/input_krs.png',
                      'KRS',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InputKrsScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      'assets/icons/daftar_nilai.png',
                      'Daftar Nilai',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TranskipPage(),
                          ),
                        );
                      },
                    ),

                    _menuItem('assets/icons/khs.png', 'Kartu Hasil Studi'),

                    _menuItem(
                      'assets/icons/sp.png',
                      'SP',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SpScreen(),
                          ),
                        );
                      },
                    ),
                    _menuItem(
                      'assets/icons/faq_circle.png',
                      'Bantuan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FaqScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(), // slot kosong biar layout mirip desain
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ====== HEADER BIRU ======
  Widget _buildBlueHeader() {
    final hasFoto =
        (user?["foto"] != null && (user?["foto"]?.toString().isNotEmpty ?? false));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF7BA7E2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BARIS SALAM + LOGO
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Semangat Pagi!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset('assets/images/swu.png'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // KARTU PROFIL
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Biodata()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: hasFoto
                        ? NetworkImage(user!["foto"])
                        : const AssetImage("assets/images/default_user.png")
                            as ImageProvider,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?["nim"] ?? "A11.2020.0000",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?["nama"] ?? "Nama Mahasiswa",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?["program_studi"]?["nama_prodi"] ??
                                    "Teknik Informatika",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Angkatan ${user?["angkatan"] ?? "2020"}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== MENU ITEM KOTAK HITAM ======
  Widget _menuItem(String assetPath, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                assetPath,
                color: Colors.white,
                width: 34,
                height: 34,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}