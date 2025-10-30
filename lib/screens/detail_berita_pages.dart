import 'package:flutter/material.dart';

class DetailBeritaPages extends StatelessWidget {
  final Map<String, dynamic> berita;

  const DetailBeritaPages({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(berita["judul"] ?? "Detail Berita"),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              berita["judul"] ?? "Judul Kosong",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Tanggal: ${berita["createdAt"] ?? "-"}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 25),
            Text(
              berita["isi"] ?? "tidak ada isi",
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
