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
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  final ImagePicker _picker = ImagePicker();
  
  // Instance FaceDetector dari ML Kit
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  Uint8List? _photoBytes;
  Position? _position;
  DateTime? _locationTime; // waktu saat lokasi diambil

  bool _isSubmitting = false;
  bool _loading = true;
  Map<String, dynamic>? _existing;

  // 🔒 Titik lokasi yang diizinkan & toleransi (meter) 
  static const double _allowedLat = -7.439290555544139;   
  static const double _allowedLon = 109.26619407574634;  
  static const double _allowedRadius = 200.0;    

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchExisting();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _faceDetector.close();
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
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) return; // User cancelled

      // Jika bukan web, lakukan deteksi wajah dengan ML Kit
      if (!kIsWeb) {
        final inputImage = InputImage.fromFilePath(image.path);
        final faces = await _faceDetector.processImage(inputImage);
        
        if (faces.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Wajah tidak terdeteksi. Silakan coba lagi.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return; // Wajah tidak valid, tolak foto
        }
      }

      final bytes = await image.readAsBytes();
      setState(() => _photoBytes = bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Wajah terdeteksi dan foto berhasil diambil'),
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

  // Foto ulang = buang foto
  void _retakePicture() {
    setState(() => _photoBytes = null);
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

  // ================== Validasi Geofence ==================
  /// Mengembalikan true jika posisi dalam radius yang diizinkan.
  Future<bool> _validateLocation() async {
    final double distance = Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      _allowedLat,
      _allowedLon,
    );

    // Debug: lihat jarak aktual di console
    debugPrint(
      '🔍 Jarak dari titik absen: ${distance.toStringAsFixed(2)} m '
      '(batas: ${_allowedRadius.toStringAsFixed(0)} m)',
    );

    if (distance <= _allowedRadius) return true;

    // Tampilkan dialog peringatan
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Diluar Area Absen'),
            ],
          ),
          content: Text(
            'Kamu berada ${distance.toStringAsFixed(0)} meter dari lokasi absensi.\n\n'
            'Batas yang diizinkan adalah ${_allowedRadius.toStringAsFixed(0)} meter.\n\n'
            'Pastikan kamu berada di lokasi yang benar dan ambil ulang lokasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
    return false;
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

    // 🔒 Validasi geofence — hentikan jika di luar area
    final bool locationValid = await _validateLocation();
    if (!locationValid) return;

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

  Widget _buildCameraPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      width: double.infinity,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Ketuk "Ambil Foto" di bawah', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _photoBytes != null 
                            ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                            : _buildCameraPlaceholder(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: OutlinedButton(
                  onPressed: _photoBytes == null ? _takePicture : _retakePicture,
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
