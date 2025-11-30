import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'biodata.dart';
import 'jadwal_screen.dart';
import 'input_krs_screen.dart';
import 'transkip.dart';
import 'sp_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const BottomNav(initialIndex: 0),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildBlueHeader(),
              const SizedBox(height: 24),

              // ABSENSI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 16),

                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const JadwalPage()));
                        },
                        borderRadius: BorderRadius.circular(16),

                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 40, 185, 27),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Absensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // MENU
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 25,
                  crossAxisSpacing: 25,

                  children: [
                    _menuItem(
                      'assets/icons/input_krs.png',
                      'KRS',
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const InputKrsScreen()));
                      },
                    ),

                    _menuItem(
                      'assets/icons/daftar_nilai.png',
                      'Transkrip Nilai',
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TranskipPage()));
                      },
                    ),

                    _menuItem('assets/icons/khs.png', 'Kartu Hasil Studi'),

                    _menuItem(
                      'assets/icons/sp.png',
                      'SP',
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SpScreen()));
                      },
                    ),

                    const SizedBox(),
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

  // HEADER
  Widget _buildBlueHeader() {
    final hasFoto =
        (user?["foto"] != null && (user?["foto"]?.toString().isNotEmpty ?? false));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
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
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/images/swu.png'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const Biodata()));
            },

            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: hasFoto
                        ? NetworkImage(user!["foto"])
                        : const AssetImage("assets/images/default_user.png")
                            as ImageProvider,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?["nim"] ?? "NIM123456"),
                        const SizedBox(height: 2),
                        Text(
                          user?["nama"] ?? "Nama Mahasiswa",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user?["program_studi"]?["nama_prodi"] ??
                                    "Program Studi",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("Angkatan ${user?["angkatan"] ?? "0"}"),
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

  // MENU ITEM
  Widget _menuItem(String assetPath, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),

      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(assetPath, color: Colors.white),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
