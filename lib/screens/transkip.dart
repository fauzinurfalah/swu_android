import 'package:flutter/material.dart';

class TranskipPage extends StatelessWidget {
  const TranskipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transkipData = [
      {"matkul": "Dasar Pemrograman", "sks": 3, "nilai": "A+"},
      {"matkul": "Matematika Diskrit", "sks": 3, "nilai": "A-"},
      {"matkul": "Basis Data", "sks": 4, "nilai": "B+"},
      {"matkul": "Pemrograman Web", "sks": 4, "nilai": "A-"},
      {"matkul": "Struktur Data", "sks": 3, "nilai": "B+"},
      {"matkul": "Kalkulus", "sks": 3, "nilai": "B+"},
      {"matkul": "Manajemen Bisnis", "sks": 2, "nilai": "A+"},
      {"matkul": "Mobile Programming", "sks": 4, "nilai": "A-"},
      {"matkul": "Bahasa Korea", "sks": 3, "nilai": "B+"},
      {"matkul": "Desktop Programming", "sks": 4, "nilai": "A-"},
      {"matkul": "Pancasila", "sks": 2, "nilai": "A+"},
      {"matkul": "Data Mining", "sks": 4, "nilai": "A+"},
      {"matkul": "Pengantar Teknologi", "sks": 3, "nilai": "A+"},
      {"matkul": "Bahasa Indonesia", "sks": 2, "nilai": "B+"},
      {"matkul": "Science", "sks": 3, "nilai": "B+"},
      {"matkul": "Rangkaian Digital", "sks": 4, "nilai": "A-"},
      {"matkul": "Bahasa Jepang", "sks": 3, "nilai": "B+"},
      {"matkul": "Agama", "sks": 2, "nilai": "A+"},
    ];

    int totalSKS = transkipData.fold<int>(
      0,
      (prev, item) => prev + (item['sks'] as int),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

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
                      'Transkip Nilai',
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
            // 🔹 Container Putih Besar
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
                child: Column(
                  children: [
                    const Text(
                      "Transkrip\nNilai",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 👤 Profil Mahasiswa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage(
                            "assets/images/profile.png",
                          ), // bisa ganti
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Kukuh Lisa",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "NIM: A11.2023.6211",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Total SKS : $totalSKS SKS",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 📊 IPS / IPK Dummy
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ipsItem("Indeks Prestasi Kumulatif", "3.78"),
                        _ipsItem("IPS Genap", "3.80"),
                        _ipsItem("IPS Ganjil", "3.76"),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Judul Tabel
                    const Text(
                      "Transkrip Nilai",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Header
                    Row(
                      children: const [
                        Expanded(flex: 6, child: Text("Mata Kuliah")),
                        Expanded(flex: 2, child: Text("SKS")),
                        Expanded(flex: 2, child: Text("Nilai")),
                      ],
                    ),
                    const Divider(),

                    // 🧾 List Nilai
                    Expanded(
                      child: ListView.builder(
                        itemCount: transkipData.length,
                        itemBuilder: (context, index) {
                          final item = transkipData[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(flex: 6, child: Text(item['matkul'])),
                                Expanded(
                                  flex: 2,
                                  child: Text(item['sks'].toString()),
                                ),
                                Expanded(flex: 2, child: Text(item['nilai'])),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Tombol Cetak
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Cetak",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ipsItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
