import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';class SppScreen extends StatefulWidget {
  const SppScreen({Key? key}) : super(key: key);

  @override
  State<SppScreen> createState() => _SppScreenState();
}

class _SppScreenState extends State<SppScreen> {
  final String _midtransServerKey = "mid-server-XXXXXXXXXXXXXXXXXXXXXXXX"; // Ganti dengan Server Key Midtrans Anda
  bool _isLoading = false;

  List<Map<String, dynamic>> sppData = [
    {
      "semester": 1,
      "tahun_ajaran": "2021/2022 Ganjil",
      "tagihan": 5000000,
      "status": "Lunas",
    },
    {
      "semester": 2,
      "tahun_ajaran": "2021/2022 Genap",
      "tagihan": 5000000,
      "status": "Lunas",
    },
    {
      "semester": 3,
      "tahun_ajaran": "2022/2023 Ganjil",
      "tagihan": 5000000,
      "status": "Lunas",
    },
    {
      "semester": 4,
      "tahun_ajaran": "2022/2023 Genap",
      "tagihan": 5000000,
      "status": "Lunas",
    },
    {
      "semester": 5,
      "tahun_ajaran": "2023/2024 Ganjil",
      "tagihan": 5200000,
      "status": "Belum Lunas",
    },
    {
      "semester": 6,
      "tahun_ajaran": "2023/2024 Genap",
      "tagihan": 5200000,
      "status": "Belum Ditagihkan",
    },
  ];

  Future<void> _processPayment(int index) async {
    Navigator.pop(context); 
    
    if (_midtransServerKey == "ISI_DENGAN_SERVER_KEY_ANDA" || _midtransServerKey.isEmpty) {
      _simulasiPembayaranSukses(index);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String authKey = base64Encode(utf8.encode("$_midtransServerKey:"));
      final dio = Dio();
      
      final dataTagihan = sppData[index];
      final targetNominal = dataTagihan['tagihan'];
      final targetSemester = dataTagihan['semester'];
      final orderId = "SPP-${DateTime.now().millisecondsSinceEpoch}-$targetSemester";

      final response = await dio.post(
        'https://app.sandbox.midtrans.com/snap/v1/transactions',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Basic $authKey',
          },
        ),
        data: {
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": targetNominal
          },
          "item_details": [
            {
              "id": "SPP-$targetSemester",
              "price": targetNominal,
              "quantity": 1,
              "name": "SPP Semester $targetSemester"
            }
          ]
        },
      );

      final redirectUrl = response.data['redirect_url'];
      if (redirectUrl != null) {
        final Uri url = Uri.parse(redirectUrl);
        await launchUrl(url, mode: LaunchMode.externalApplication);
        setState(() {
          sppData[index]['status'] = 'Lunas';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuka payment gateway: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _simulasiPembayaranSukses(int index) {
    setState(() {
      sppData[index]['status'] = 'Lunas';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pembayaran Semester ${sppData[index]['semester']} berhasil!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _bayarSpp(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Konfirmasi Pembayaran"),
          content: Text(
            "Apakah Anda yakin ingin membayar SPP untuk Semester ${sppData[index]['semester']} sejumlah Rp. ${sppData[index]['tagihan']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA7E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _processPayment(index),
              child: const Text("Bayar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          "Pembayaran SPP",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sppData.length,
            itemBuilder: (context, index) {
              final data = sppData[index];
              final bool isLunas = data['status'] == "Lunas";
              final bool isBelumLunas = data['status'] == "Belum Lunas";

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Semester ${data['semester']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7BA7E2),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLunas
                                ? Colors.green.withOpacity(0.1)
                                : isBelumLunas
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['status'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLunas
                                  ? Colors.green
                                  : isBelumLunas
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tahun Ajaran: ${data['tahun_ajaran']}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tagihan: Rp. ${data['tagihan'].toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (isBelumLunas) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7BA7E2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _bayarSpp(index),
                          child: const Text(
                            "Bayar Sekarang",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF7BA7E2)),
              ),
            ),
        ],
      ),
    );
  }
}
