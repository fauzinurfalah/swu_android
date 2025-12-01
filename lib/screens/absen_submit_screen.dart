import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

// Web-specific imports
import 'webcam_helper.dart' if (dart.library.io) 'webcam_helper_stub.dart';

class AbsenSubmitScreen extends StatefulWidget {
  final int idKrsDetail;
  final int pertemuan;
  final String namaMatkul;

  const AbsenSubmitScreen({
    super.key,
    required this.idKrsDetail,
    required this.pertemuan,
    required this.namaMatkul,
  });

  @override
  State<AbsenSubmitScreen> createState() => _AbsenSubmitScreenState();
}

class _AbsenSubmitScreenState extends State<AbsenSubmitScreen> {
  final WebCamera cam = WebCamera();

  Uint8List? _photoBytes;
  Position? _position;
  DateTime? _locationTime; // waktu saat lokasi diambil

  bool _isSubmitting = false;
  bool _loading = true;
  bool _isCameraReady = false;
  Map<String, dynamic>? _existing;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchExisting();

    if (_existing == null && kIsWeb) {
      // Initialize camera only on web and if not submitted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCameraAfterRender();
      });
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initializeCameraAfterRender() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await cam.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
        debugPrint("✅ Camera initialized successfully");
      }
    } catch (e) {
      debugPrint("❌ Error init camera: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal akses kamera: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      cam.dispose(); // matikan stream kamera saat keluar screen
    }
    super.dispose();
  }

  Future<void> _fetchExisting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.validateStatus = (_) => true;

      final url =
          "${ApiService.baseUrl}absensi/detail?id_krs_detail=${widget.idKrsDetail}&pertemuan=${widget.pertemuan}";
      final res = await dio.get(url);
      if (res.statusCode == 200 &&
          res.data != null &&
          res.data['data'] != null) {
        _existing = Map<String, dynamic>.from(res.data['data']);
      } else {
        _existing = null;
      }
    } catch (e) {
      _existing = null;
    }
  }

  Future<void> _takePicture() async {
    try {
      final data = await cam.capture();
      setState(() => _photoBytes = data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto berhasil diambil'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Foto ulang = ambil foto baru lagi dari kamera
  Future<void> _retakePicture() async {
    await _takePicture();
  }

  /// 🔹 Versi _getLocation disederhanakan seperti contoh AbsenSubmitPage
  Future<void> _getLocation() async {
    try {
      // Cek apakah layanan lokasi aktif
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lokasi tidak aktif"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Cek & minta izin
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Izin lokasi ditolak, aktifkan di pengaturan"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 🔥 Versi simpel seperti di kode contoh
      final pos = await Geolocator.getCurrentPosition();

      setState(() {
        _position = pos;
        _locationTime = DateTime.now(); // simpan waktu saat lokasi diambil
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lokasi berhasil diambil"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mengambil lokasi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================== _submit ==================
  Future<void> _submit() async {
    if (_existing != null) {
      Navigator.pop(context, true);
      return;
    }

    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto belum diambil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum diambil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.validateStatus = (_) => true;

      final file = MultipartFile.fromBytes(
        _photoBytes!,
        filename: "absen_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      final form = FormData.fromMap({
        "id_krs_detail": widget.idKrsDetail,
        "pertemuan": widget.pertemuan,
        "latitude": _position!.latitude,
        "longitude": _position!.longitude,
        "foto": file,
      });

      final res = await dio.post(
        "${ApiService.baseUrl}absensi/submit",
        data: form,
      );

      print("🔵 STATUS CODE: ${res.statusCode}");
      print("🔵 DATA: ${res.data}");

      final statusCode = res.statusCode ?? 0;
      final data = res.data;

      final isSuccess =
          (statusCode >= 200 && statusCode < 300) ||
          data?['status'] == true ||
          data?['status'] == 1 ||
          data?['status'] == 'success' ||
          data?['status'] == 200;

      if (isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(data?['message'] ?? '✅ Absensi berhasil disubmit'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
        return;
      }

      final msg = data?['message'] ?? 'Gagal submit';
      throw Exception(msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal submit absen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  // =============================================================

  Widget _buildNotSubmittedView() {
    return Column(
      children: [
        // Main Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Presensi Mahasiswa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pertemuan ${widget.pertemuan}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.namaMatkul,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Live Camera (selalu tampil di web)
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? const HtmlElementView(
                          viewType: WebCamera.viewType,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Kamera hanya tersedia di versi web'),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Preview foto yang sudah diambil (kalau ada)
              if (_photoBytes != null) ...[
                const Text(
                  'Foto Terakhir:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photoBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Ambil Foto / Foto Ulang Button
              Center(
                child: OutlinedButton(
                  onPressed: (_isCameraReady || !kIsWeb)
                      ? (_photoBytes == null ? _takePicture : _retakePicture)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _photoBytes == null ? 'Ambil Foto' : 'Foto Ulang',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Location Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi :',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _position != null
                    ? 'Lat : ${_position!.latitude.toStringAsFixed(6)}\nLong : ${_position!.longitude.toStringAsFixed(6)}'
                    : 'Belum diambil',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Waktu : ${_locationTime != null
                    ? DateFormat("HH.mm").format(_locationTime!)
                    : '-'}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _getLocation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Ambil Lokasi & Waktu'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Hadir Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Hadir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSubmittedView() {
    final fotoUrl =
        _existing?['foto'] ?? _existing?['file'] ?? _existing?['url_foto'];
    final lat = double.tryParse(
        (_existing?['latitude'] ?? _existing?['lat'] ?? '0').toString());
    final lon = double.tryParse(
        (_existing?['longitude'] ??
                _existing?['lng'] ??
                _existing?['long'] ??
                '0')
            .toString());
    final waktu =
        _existing?['created_at'] ?? _existing?['waktu'] ?? _existing?['time'];

    return Column(
      children: [
        // Main Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Presensi Mahasiswa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pertemuan ${widget.pertemuan}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.namaMatkul,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Photo
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: fotoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          fotoUrl.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image)),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 16),

              // Map
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (lat != null && lon != null)
                      ? FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(lat, lon),
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(lat, lon),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Center(child: Text("Lokasi tidak valid")),
                ),
              ),

              const SizedBox(height: 16),

              // Details
              Text(
                'Pertemuan : ${widget.pertemuan}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Latitude : ${lat?.toStringAsFixed(6) ?? '-'}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'Longitude : ${lon?.toStringAsFixed(6) ?? '-'}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Waktu : ${waktu ?? '-'}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Anda Hadir Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {}, // Already submitted
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.green.shade700, width: 2),
                ),
              ),
              child: const Text(
                'Anda Hadir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on status
    final bgColor = _existing != null
        ? const Color(0xFF4CAF50) // Green
        : const Color(0xFF95A5A6); // Gray

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submit Presensi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue,
              child: Image.asset(
                'assets/images/swu.png',
                width: 20,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: _existing == null
                  ? _buildNotSubmittedView()
                  : _buildSubmittedView(),
            ),
    );
  }
}
