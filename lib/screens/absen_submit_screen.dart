import 'dart:typed_data';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Web-specific imports
import 'webcam_helper.dart' if (dart.library.io) 'webcam_helper_stub.dart';
import 'package:camera/camera.dart';

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

    if (_existing == null) {
      // Initialize camera on both web and Android if not submitted
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
    cam.dispose(); // matikan stream kamera saat keluar screen (web & Android)
    super.dispose();
  }

  Future<void> _fetchExisting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('absen_${widget.idKrsDetail}_${widget.pertemuan}');
      if (dataStr != null) {
        _existing = Map<String, dynamic>.from(jsonDecode(dataStr));
      } else {
        // DUMMY DATA: Jika pertemuan 1 sampai 3, set dummy existing data
        if (widget.pertemuan <= 3) {
          _existing = {
            "id_krs_detail": widget.idKrsDetail,
            "pertemuan": widget.pertemuan,
            "latitude": -6.914744,
            "longitude": 107.609810,
            "waktu": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now().subtract(Duration(days: (4 - widget.pertemuan) * 7))),
            "foto": "https://i.pravatar.cc/150?img=3",
          };
        } else {
          _existing = null;
        }
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

      final dataToSave = {
        "id_krs_detail": widget.idKrsDetail,
        "pertemuan": widget.pertemuan,
        "latitude": _position!.latitude,
        "longitude": _position!.longitude,
        "waktu": DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()),
        "foto": base64Encode(_photoBytes!), // Simpan foto asli sebagai base64 string
      };

      await prefs.setString('absen_${widget.idKrsDetail}_${widget.pertemuan}', jsonEncode(dataToSave));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Absensi berhasil disubmit secara lokal'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, true);
      }
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

  Widget _buildCameraPreview() {
    if (kIsWeb) {
      // Web: gunakan HtmlElementView
      return const HtmlElementView(
        viewType: WebCamera.viewType,
      );
    } else {
      // Android: gunakan CameraPreview dari package camera
      if (_isCameraReady && cam.controller != null) {
        final size = MediaQuery.of(context).size;
        // Calculate scale to cover the 1:1 aspect ratio
        // Camera preview aspect ratio is usually 4:3 or 16:9
        // We want to fill a 1:1 box.
        // Since we are inside an AspectRatio(1), the parent width == height.
        // The CameraPreview tries to fit inside.
        // To cover, we need to scale it up.
        
        var scale = 1.0;
        try {
            final previewSize = cam.controller!.value.previewSize!;
            // previewSize is usually landscape (e.g. 640x480).
            // But on mobile portrait, the preview is rotated.
            // Aspect ratio of the widget is previewSize.height / previewSize.width (if portrait)
            // Actually CameraPreview handles rotation.
            // Let's rely on the aspect ratio of the controller.
            final aspectRatio = cam.controller!.value.aspectRatio;
            
            // If aspect ratio is not 1, we need to scale.
            // If portrait, aspectRatio < 1 (e.g. 3/4 = 0.75).
            // To fill a square (1.0), we need to scale by 1/aspectRatio (1/0.75 = 1.33)
            // If landscape, aspectRatio > 1 (e.g. 4/3 = 1.33).
            // To fill a square, we need to scale by aspectRatio (1.33).
            
            scale = 1 / aspectRatio;
            if (scale < 1) scale = 1 / scale; 
        } catch (e) {
            scale = 1.0;
        }

        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: CameraPreview(cam.controller!),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Memuat kamera...'),
            ],
          ),
        );
      }
    }
  }

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

              // Live Camera (web & Android)
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildCameraPreview(),
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
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _photoBytes!,
                        fit: BoxFit.cover,
                      ),
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: fotoUrl.toString().startsWith('http')
                              ? Image.network(
                                  fotoUrl.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Icon(Icons.broken_image)),
                                )
                              : Image.memory(
                                  base64Decode(fotoUrl.toString()),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Icon(Icons.broken_image)),
                                ),
                        )
                      : const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
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
                              userAgentPackageName: 'com.example.project_mobileprog',
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
