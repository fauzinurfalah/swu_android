import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

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
  XFile? _photoFile;
  Position? _position;
  bool _isSubmitting = false;
  bool _loading = true;
  Map<String, dynamic>? _existing; // jika sudah terisi, data history
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchExisting();
    if (mounted) setState(() => _loading = false);
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

  Future<void> _pickCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (x != null) {
        setState(() => _photoFile = x);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal membuka kamera')));
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi tidak aktif')),
          );
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _position = pos);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengambil lokasi')));
    }
  }

  Future<void> _submit() async {
    if (_existing != null) {
      Navigator.pop(context, true);
      return;
    }

    if (_photoFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto belum diambil')));
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lokasi belum diambil')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio();
      if (token != null) dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.validateStatus = (_) => true;

      final file = await MultipartFile.fromFile(
        _photoFile!.path,
        filename: "absen_${DateTime.now().millisecondsSinceEpoch}.jpg",
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

      final message = (res.data is Map)
          ? (res.data['message'] ?? 'Submit berhasil')
          : 'Submit berhasil';

      // tampilkan overlay sukses lalu kembali dengan true
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(
                    vertical: 26,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Submit Sukses',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // kembalikan hasil true ke halaman sebelumnya agar berubah menjadi hijau
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal submit absen'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presensi Mahasiswa',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat("EEEE, d MMMM yyyy", "id_ID").format(DateTime.now()),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            widget.namaMatkul,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Pertemuan ${widget.pertemuan}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildNotSubmittedView() {
    return Column(
      children: [
        // preview foto area
        Container(
          width: double.infinity,
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _photoFile == null
              ? Center(
                  child: Text(
                    'Belum ambil foto',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photoFile!.path), fit: BoxFit.cover),
                ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickCamera,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Ambil Foto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
          ),
        ),

        const SizedBox(height: 18),

        // lokasi preview
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _position == null
                    ? 'Belum diambil'
                    : 'Lat: ${_position!.latitude}, Long: ${_position!.longitude}',
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Ambil Lokasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Hadir'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedView() {
    // gunakan data dari _existing
    final fotoUrl =
        _existing?['foto'] ?? _existing?['file'] ?? _existing?['url_foto'];
    final lat = _existing?['latitude'] ?? _existing?['lat'];
    final lon =
        _existing?['longitude'] ?? _existing?['lng'] ?? _existing?['long'];
    final waktu =
        _existing?['created_at'] ?? _existing?['waktu'] ?? _existing?['time'];

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
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
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pertemuan: ${widget.pertemuan}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text('Latitude: ${lat ?? '-'}'),
              Text('Longitude: ${lon ?? '-'}'),
              const SizedBox(height: 6),
              Text('Waktu: ${waktu ?? '-'}'),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text('Hadir'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // logo kampus di pojok kanan atas (sama gaya seperti input_krs_screen)
    final logoWidget = Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset('assets/images/swu.png', fit: BoxFit.contain),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF7BA7E2),
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: const Color(0xFF7BA7E2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Submit Presensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  logoWidget,
                ],
              ),
            ),

            // white rounded header (tidak menampilkan foto user)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: _buildHeader(),
            ),

            // content area
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _existing == null
                            ? _buildNotSubmittedView()
                            : _buildSubmittedView(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
