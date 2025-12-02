import 'package:flutter/material.dart';
import 'sp_detail_screen.dart';

class SpScreen extends StatefulWidget {
  const SpScreen({super.key});

  @override
  State<SpScreen> createState() => _SpScreenState();
}

class _SpScreenState extends State<SpScreen> {
  List<Map<String, dynamic>> spList = [
    {
      "kode": "SP001",
      "nama": "Algoritma & Pemrograman",
      "sks": 3,
      "dosen": "Dr. Budi Santoso",
      "jadwal": "Senin, 09:00 - 10:40",
    },
    {
      "kode": "SP002",
      "nama": "Basis Data",
      "sks": 3,
      "dosen": "Maya Indah M.Kom",
      "jadwal": "Selasa, 10:00 - 11:40",
    },
    {
      "kode": "SP003",
      "nama": "Pemrograman Mobile",
      "sks": 3,
      "dosen": "Rizky Ananda M.Kom",
      "jadwal": "Rabu, 13:00 - 15:00",
    },
  ];

  // Controller untuk input form dialog
  final TextEditingController kodeC = TextEditingController();
  final TextEditingController namaC = TextEditingController();
  final TextEditingController sksC = TextEditingController();
  final TextEditingController dosenC = TextEditingController();
  final TextEditingController jadwalC = TextEditingController();

  void _showAddSPDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tambah Mata Kuliah SP"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: kodeC, decoration: const InputDecoration(labelText: "Kode")),
                TextField(controller: namaC, decoration: const InputDecoration(labelText: "Nama Mata Kuliah")),
                TextField(controller: sksC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "SKS")),
                TextField(controller: dosenC, decoration: const InputDecoration(labelText: "Dosen")),
                TextField(controller: jadwalC, decoration: const InputDecoration(labelText: "Jadwal")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (kodeC.text.isNotEmpty &&
                    namaC.text.isNotEmpty &&
                    sksC.text.isNotEmpty &&
                    dosenC.text.isNotEmpty &&
                    jadwalC.text.isNotEmpty) {
                  
                  setState(() {
                    spList.add({
                      "kode": kodeC.text,
                      "nama": namaC.text,
                      "sks": int.parse(sksC.text),
                      "dosen": dosenC.text,
                      "jadwal": jadwalC.text,
                    });
                  });

                  kodeC.clear();
                  namaC.clear();
                  sksC.clear();
                  dosenC.clear();
                  jadwalC.clear();

                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7BA7E2),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showAddSPDialog();
        },
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Header
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
                      'SP (Semester Pendek)',
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

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daftar Mata Kuliah SP",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.builder(
                        itemCount: spList.length,
                        itemBuilder: (context, index) {
                          final sp = spList[index];
                          return _spItem(
                            context,
                            kode: sp["kode"],
                            nama: sp["nama"],
                            sks: sp["sks"],
                            dosen: sp["dosen"],
                            jadwal: sp["jadwal"],
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

  Widget _spItem(BuildContext context,
      {required String kode,
      required String nama,
      required int sks,
      required String dosen,
      required String jadwal}) {
    return InkWell(
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => SPDetailScreen(
              kode: kode,
              nama: nama,
              sks: sks,
              dosen: dosen,
              jadwal: jadwal,
            ),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$kode - $nama",
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("SKS : $sks"),
            Text("Dosen : $dosen"),
            Text("Jadwal : $jadwal"),
          ],
        ),
      ),
    );
  }
}