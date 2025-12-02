import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy notification data
    final List<Map<String, dynamic>> notifications = [
      {
        "title": "Pendaftaran Mata Kuliah Semester Genap",
        "description": "Pendaftaran mata kuliah semester genap telah dibuka. Silakan lakukan KRS sebelum 15 Desember 2025.",
        "date": "2025-11-28",
        "isRead": true,
      },
      {
        "title": "Update Sistem Akademik",
        "description": "Sistem akademik akan mengalami maintenance pada 5 Desember 2025 pukul 00.00 - 04.00 WIB.",
        "date": "2025-11-25",
        "isRead": false,
      },
      {
        "title": "Pembayaran SPP Semester Genap",
        "description": "Batas akhir pembayaran SPP semester genap adalah 30 Desember 2025.",
        "date": "2025-11-15",
        "isRead": true,
      },
      {
        "title": "Wisuda Periode Januari 2026",
        "description": "Pendaftaran wisuda untuk periode Januari 2026 telah dibuka. Info lebih lanjut di bagian akademik.",
        "date": "2025-11-10",
        "isRead": true,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/swu.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Notification List
              ListView.builder(
                itemCount: notifications.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final isRead = notification["isRead"] as bool;
                  
                  final bgColor = !isRead
                      ? Colors.blue.shade300
                      : Colors.grey.shade200;
                  final titleColor = !isRead
                      ? Colors.white
                      : Colors.black87;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification["title"] as String,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tanggal: ${notification["date"]}",
                            style: TextStyle(
                              fontSize: 12,
                              color: titleColor.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notification["description"] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: titleColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
