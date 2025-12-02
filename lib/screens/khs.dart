import 'package:flutter/material.dart';

class KhsPage extends StatefulWidget {
  // 🟢 Tambahkan field untuk data mahasiswa
  final String nama;
  final String nim;
  final int semester; // Asumsi semester adalah integer

  const KhsPage({
    super.key,
    required this.nama,
    required this.nim,
    required this.semester,
  });

  @override
  State<KhsPage> createState() => _KhsPageState();
}

class _KhsPageState extends State<KhsPage> {
  // Data matkul KHS — DISAMAKAN DENGAN UI/UX
  List<Map<String, dynamic>> khsList = [
    {"matkul": "Algoritma & Pemrograman", "sks": 3, "nilai": "A"},
    {"matkul": "Basis Data", "sks": 3, "nilai": "A-"},
    {"matkul": "Pemrograman Mobile", "sks": 3, "nilai": "A"},
    {"matkul": "Matematika Diskrit", "sks": 3, "nilai": "B+"},
    {"matkul": "Sistem Operasi", "sks": 3, "nilai": "A"},
    {"matkul": "Jaringan Komputer", "sks": 3, "nilai": "B"},
    {"matkul": "Bahasa Inggris", "sks": 2, "nilai": "A"},
    {"matkul": "Pendidikan Kewarganegaraan", "sks": 2, "nilai": "A"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      // floatingActionButton removed

      body: SafeArea(
        child: Column(
          children: [
            // ... (Kode Header tidak diubah) ...
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF7BA7E2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'KHS (Kartu Hasil Studi)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                      child: Image.asset('assets/images/swu.png', fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),

            // ===========================
            // ⬇ ISI KHS — DISAMAKAN UI/UX
            // ===========================
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // JUDUL TENGAH
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "Kartu Hasil",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Studi",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // INFO MAHASISWA
                    // 🟢 MENGGUNAKAN DATA DARI WIDGET
                    Text(
                      "Semester ${widget.semester}",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    // 🟢 MENGGABUNGKAN NAMA DAN NIM DARI WIDGET
                    Text(
                      "${widget.nama} • ${widget.nim}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ... (Kode Tabel tidak diubah) ...
                    Row(
                      children: const [
                        Expanded(
                          flex: 5,
                          child: Text(
                            "Mata Kuliah",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "SKS",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Nilai",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1),

                    const SizedBox(height: 6),

                    // LIST NILAI
                    Expanded(
                      child: ListView.builder(
                        itemCount: khsList.length,
                        itemBuilder: (context, index) {
                          final item = khsList[index];

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      "#${index + 1} ${item['matkul']}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item["sks"].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item["nilai"],
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                            ],
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