// Implementation untuk platform Android
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

      // Punya dua mode: satu untuk foto, default format iOS: bgra8888, Android yuv420
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
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
      // Hentikan stream apabila aktif agar bisa ambil foto
      final bool wasStreaming = _controller!.value.isStreamingImages;
      if (wasStreaming) {
        await stopFaceDetection();
        await Future.delayed(const Duration(milliseconds: 300));
      }

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
    stopFaceDetection();
    _faceDetector.close();
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  // ========================== ML KIT FACE DETECTION ==========================
  
  bool _isFaceDetected = false;
  bool get isFaceDetected => _isFaceDetected;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isDetecting = false;

  Future<void> startFaceDetection(Function(bool) onResult) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isStreamingImages) return;

    try {
      await _controller!.startImageStream((CameraImage image) async {
        if (_isDetecting) return;
        _isDetecting = true;
        
        try {
          final inputImage = _inputImageFromCameraImage(image);
          if (inputImage == null) {
            _isDetecting = false;
            return;
          }
          
          final faces = await _faceDetector.processImage(inputImage);
          _isFaceDetected = faces.isNotEmpty;
          onResult(_isFaceDetected);
        } catch (e) {
          debugPrint('Face detection error: $e');
        } finally {
          _isDetecting = false;
        }
      });
    } catch (e) {
      debugPrint('Failed to start face detection stream: $e');
    }
  }

  Future<void> stopFaceDetection() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping stream: $e');
      }
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameras == null || _cameras!.isEmpty) return null;
    
    CameraDescription frontCamera;
    try {
      frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
    } catch (e) {
      frontCamera = _cameras!.first;
    }

    final sensorOrientation = frontCamera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[DeviceOrientation.portraitUp];
      if (rotationCompensation == null) return null;
      if (frontCamera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    
    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format ?? InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }
}
