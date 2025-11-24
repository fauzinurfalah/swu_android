import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailBeritaPages extends StatelessWidget {
  final Map<String, dynamic> berita;

  const DetailBeritaPages({super.key, required this.berita});

  String _formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    try {
      final dt = DateTime.parse(raw); 
      return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String tanggal = _formatTanggal(berita["createdAt"]);

    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Column(
        children: [
          // ===== HEADER BIRU =====
          SafeArea(
            bottom: false,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
              ),
            ),
          ),

          // ===== CARD PUTIH =====
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris tanggal + icon bintang
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tanggal,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.star, color: Colors.white, size: 18),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      berita["judul"],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      berita["isi"],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
