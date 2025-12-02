// Implementation untuk platform Android
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import 'package:image/image.dart' as img;

class WebCamera {
  // Dummy constant untuk kompatibilitas dengan kode web
  static const String viewType = 'webcam-view';

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      // Dapatkan daftar kamera yang tersedia
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('Tidak ada kamera yang tersedia');
      }

      // Pilih kamera depan (front camera)
      CameraDescription frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // Jika tidak ada kamera depan, gunakan kamera pertama yang tersedia
        frontCamera = _cameras!.first;
      }

      // Inisialisasi controller dengan resolusi medium
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize controller
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw Exception('Gagal akses kamera: $e');
    }
  }

  CameraController? get controller => _controller;

  bool get isInitialized => _isInitialized && (_controller?.value.isInitialized ?? false);

  Future<Uint8List> capture() async {
    if (!isInitialized || _controller == null) {
      throw Exception('Camera belum di-initialize');
    }

    try {
      // Ambil gambar
      final XFile image = await _controller!.takePicture();
      
      // Baca bytes dari file
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Crop to square using image package
      final img.Image? original = img.decodeImage(imageBytes);
      if (original != null) {
        final int size = original.width < original.height ? original.width : original.height;
        final int x = (original.width - size) ~/ 2;
        final int y = (original.height - size) ~/ 2;
        
        final img.Image cropped = img.copyCrop(original, x: x, y: y, width: size, height: size);
        
        // Return as PNG to match web implementation and filename extension
        return Uint8List.fromList(img.encodePng(cropped));
      }

      return imageBytes;
    } catch (e) {
      throw Exception('Gagal mengambil gambar: $e');
    }
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
