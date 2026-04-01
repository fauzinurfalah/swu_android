import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:camera/camera.dart';

class WebCamera {

  WebCamera._internal() {
    _registerViewFactoryOnce();
  }
  static final WebCamera _instance = WebCamera._internal();
  factory WebCamera() => _instance;

  static const String viewType = 'webcam-view';
  static bool _viewRegistered = false;

  // Dummy controller for interface compatibility
  CameraController? get controller => null;

  html.VideoElement? _video;
  html.MediaStream? _stream;
  html.CanvasElement? _canvas;

  void _registerViewFactoryOnce() {
    if (_viewRegistered) return;


    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {

        _video ??= html.VideoElement()
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';

        return _video!;
      },
    );

    _viewRegistered = true;
  }

  Future<void> initialize() async {

    _canvas ??= html.CanvasElement();

    _video ??= html.VideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    if (_stream != null && _stream!.active == true) {
      _video!.srcObject = _stream;
      return;
    }

    try {
      _stopStreamInternal();

      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });

      if (_stream != null) {
        _video!.srcObject = _stream;
      }
    } catch (e) {
      throw Exception('Gagal akses kamera: $e');
    }
  }

  Future<Uint8List> capture() async {
    if (_video == null || _canvas == null) {
      throw Exception('Camera belum di-initialize');
    }

    var width = _video!.videoWidth;
    var height = _video!.videoHeight;

    if (width == 0 || height == 0) {
      await _video!.onLoadedMetadata.first;
      width = _video!.videoWidth;
      height = _video!.videoHeight;
    }

    // Calculate square crop
    var size = width < height ? width : height;
    var x = (width - size) / 2;
    var y = (height - size) / 2;

    _canvas!
      ..width = size
      ..height = size;

    final ctx = _canvas!.context2D;
    // drawImageScaledFromSource(image, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight)
    ctx.drawImageScaledFromSource(_video!, x, y, size, size, 0, 0, size, size);

    final blob = await _canvas!.toBlob('image/png');
    if (blob == null) {
      throw Exception('Gagal membuat blob dari canvas');
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoad.first;

    return reader.result as Uint8List;
  }

  void _stopStreamInternal() {
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
    if (_video != null) {
      _video!.srcObject = null;
    }
  }

  void dispose() {
    _stopStreamInternal();
  }

  // Dummy face detection APIs untuk kompatibilitas dengan WebCamera di Android/iOS
  bool get isFaceDetected => true; // Di web selalu dianggap true (karena ML Kit tidak disupport)

  Future<void> startFaceDetection(Function(bool) onResult) async {
    // Pada web, kirim hasil true (terdeteksi)
    onResult(true);
  }

  Future<void> stopFaceDetection() async {
    // Do nothing
  }
}
