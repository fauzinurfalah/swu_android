import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'home_screen.dart';

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({Key? key}) : super(key: key);

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  String today = "";

  // Dummy data mata kuliah
  final List<Map<String, dynamic>> mataKuliah = [
    {
      "kode": "#127",
      "nama": "Mobile Programming",
      "dosen": "Mr. Dosen, S. Kom",
      "pertemuan": "Pertemuan ke-6",
      "ruang": "Lab. 1.2",
      "jam": "09:00 - 11.00 WIB",
      "warna": Colors.green,
    },
    {
      "kode": "#86",
      "nama": "Bahasa Indonesia",
      "dosen": "Ms. Dosen, S. Kom",
      "pertemuan": "Pertemuan ke-6",
      "ruang": "Rg. 2.3",
      "jam": "09:00 - 11.00 WIB",
      "warna": Colors.grey,
    },
    {
      "kode": "#102",
      "nama": "Basis Data",
      "dosen": "Mr. Data, M.Kom",
      "pertemuan": "Pertemuan ke-5",
      "ruang": "Lab. 3.1",
      "jam": "13:00 - 15.00 WIB",
      "warna": Colors.blueGrey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initLocale();
  }

  Future<void> _initLocale() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      today = DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            // ====== HEADER ======
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol back
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    ),
                  ),

                  // Logo bulat kanan atas
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

            // ====== BAGIAN PUTIH (TITLE & TANGGAL) ======
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Absensi",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    today.isNotEmpty ? today : "Memuat tanggal...",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            // ====== LIST SCROLLABLE ======
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: mataKuliah.length,
                  itemBuilder: (context, index) {
                    final mk = mataKuliah[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: mk["warna"],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${mk["kode"]} ${mk["nama"]}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mk["dosen"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            mk["pertemuan"],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildTag(mk["ruang"]),
                              const SizedBox(width: 8),
                              _buildTag(mk["jam"]),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
