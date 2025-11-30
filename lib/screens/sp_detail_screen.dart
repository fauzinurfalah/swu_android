import 'package:flutter/material.dart';

class SPDetailScreen extends StatelessWidget {
  // gunakan constructor yang menerima nilai (non-const) jika ingin menampilkan item spesifik
  final String kode;
  final String nama;
  final int sks;
  final String dosen;
  final String jadwal;

  const SPDetailScreen({
    super.key,
    this.kode = "SP000",
    this.nama = "Nama Mata Kuliah",
    this.sks = 0,
    this.dosen = "Dosen",
    this.jadwal = "Jadwal",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF7BA7E2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Detail Mata Kuliah SP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    Text(
                      "$kode - $nama",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("SKS : $sks", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Dosen Pengampu : $dosen", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Jadwal : $jadwal", style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // contoh aksi daftar SP
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Pendaftaran SP terkirim")),
                          );
                        },
                        child: const Text("Daftar Mata Kuliah Ini"),
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
