import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../api/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? user;

  final List<Map<String, dynamic>> menuItems = [
    {"icon": Icons.school, "label": "KRS"},
    {"icon": Icons.grade, "label": "KHS"},
    {"icon": Icons.calendar_month, "label": "Jadwal"},
    {"icon": Icons.person, "label": "Profil"},
    {"icon": Icons.bar_chart, "label": "IPK"},
    {"icon": Icons.help, "label": "Bantuan"},
    {"icon": Icons.settings, "label": "Pengaturan"},
  ];

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
      
      print("Debug - Token: $token");
      print("Debug - Email: $email");

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-type'] = 'application/json';

      print("Debug - Making API request to: ${ApiService.baseUrl}mahasiswa/detail-mahasiswa");
      final response = await dio.post(
        "${ApiService.baseUrl}mahasiswa/detail-mahasiswa",
        data: {"email": email},
      );
      print("Debug - API Response: ${response.data}");
      setState(() {
        user = response.data["data"];
      });
      print("Debug - User data set: $user");
    } catch (e) {
      print("Error getMahasiswa: $e");
      print("Error details: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Mahasiswa"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== PROFILE CARD =====
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: user?["foto"] != null ? NetworkImage(user!["foto"]) : null,
                    child: user?["foto"] == null ? Icon(Icons.person, size: 35) : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?["nama"] ?? "Loading...",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(user?["email"] ?? ""),
                        Text(user?["nim"] ?? ""),
                        Text(
                          user?["program_studi"] != null 
                              ? "${user!["program_studi"]["nama_prodi"]}-${user!["angkatan"]}"
                              : "",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ===== MENU GRID =====
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: menuItems
                  .map(
                    (item) => Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(
                            item["icon"],
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item["label"],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            
          ],
        ),
      ),

      bottomNavigationBar: const BottomNav(initialIndex: 0),
    );
  }
}
