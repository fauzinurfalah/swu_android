import 'dart:typed_data';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

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
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  bool _faceDetected = false;

  Uint8List? _photoBytes;
  Position? _position;
  DateTime? _locationTime;

  bool _isSubmitting = false;
  bool _loading = true;
  Map<String, dynamic>? _existing;

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
    if (mounted) {
      setState(() => _loading = false);
      if (_existing == null && !kIsWeb) {
        _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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

  Future<void> _takePictureManual() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      frontCamera ??= _cameras!.first;

      _cameraController = CameraController(
        frontCamera,
        kDebugMode ? ResolutionPreset.low : ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android 
            ? ImageFormatGroup.nv21 
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
      });

      _startFaceDetection();
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  int _lastDetectTime = 0;

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _faceDetected = false;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting || _faceDetected) return;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastDetectTime < 500) return;
      _lastDetectTime = currentTime;

      _isDetecting = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage != null) {
          final faces = await _faceDetector.processImage(inputImage);
          if (faces.isNotEmpty) {
            _faceDetected = true;
            await _cameraController!.stopImageStream();
            
            final XFile picture = await _cameraController!.takePicture();
            final bytes = await picture.readAsBytes();
            
            if (mounted) {
              setState(() {
                _photoBytes = bytes;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Wajah terdeteksi dan foto diambil otomatis'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      } catch (e) {
        debugPrint("Error face detection: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.isEmpty) return null;

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _retakePicture() {
    setState(() => _photoBytes = null);
    if (!kIsWeb && _isCameraInitialized) {
      _startFaceDetection();
    }
  }

  Future<void> _getLocation() async {
    try {
  
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
        _locationTime = DateTime.now(); 
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
  Future<bool> _validateLocation() async {
    if (kDebugMode) {
      debugPrint('DEBUG] Bypass Geofence untuk testing lebih cepat');
      return true; 
    }

    final double distance = Geolocator.distanceBetween(
      _position!.latitude,
      _position!.longitude,
      _allowedLat,
      _allowedLon,
    );

    debugPrint(
      '🔍 Jarak dari titik absen: ${distance.toStringAsFixed(2)} m '
      '(batas: ${_allowedRadius.toStringAsFixed(0)} m)',
    );

    if (distance <= _allowedRadius) return true;

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

    // Validasi geofence 
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
        "foto": base64Encode(_photoBytes!), 
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

              // Live Camera
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _photoBytes != null 
                            ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                            : (kIsWeb 
                                ? _buildCameraPlaceholder() 
                                : (_isCameraInitialized 
                                    ? CameraPreview(_cameraController!) 
                                    : const Center(child: CircularProgressIndicator()))),
                      ),
                      if (_photoBytes == null && !kIsWeb && _isCameraInitialized)
                         Positioned(
                           bottom: 16,
                           left: 0,
                           right: 0,
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               if (kDebugMode)
                                 ElevatedButton(
                                   onPressed: () async {
                                     _faceDetected = true;
                                     await _cameraController!.stopImageStream();
                                     final XFile picture = await _cameraController!.takePicture();
                                     final bytes = await picture.readAsBytes();
                                     if (mounted) setState(() => _photoBytes = bytes);
                                   },
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                   child: const Text('Bypass Face (Debug)'),
                                 ),
                               const Center(
                                 child: Text(
                                   'Arahkan wajah Anda ke kamera...',
                                   style: TextStyle(
                                     color: Colors.white,
                                     fontWeight: FontWeight.bold,
                                     shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: OutlinedButton(
                  onPressed: _photoBytes == null ? (kIsWeb ? _takePictureManual : null) : _retakePicture,
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
                    _photoBytes == null ? (kIsWeb ? 'Ambil Foto' : 'Mendeteksi Wajah...') : 'Foto Ulang',
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
              onPressed: () {}, 
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
