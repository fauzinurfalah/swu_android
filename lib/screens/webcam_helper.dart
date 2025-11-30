// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebCamera {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  html.CanvasElement? _canvas;

  static const String viewType = 'webcam-view';

  Future<void> initialize() async {
    // 1. Buat video element
    _video = html.VideoElement()
      ..autoplay = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // 2. Minta akses kamera
    try {
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'}, // front camera
        'audio': false,
      });

      if (_stream != null) {
        _video!.srcObject = _stream;
      }
    } catch (e) {
      throw Exception('Gagal akses kamera: $e');
    }

    // 3. Register ke platform view
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => _video!,
    );

    // 4. Buat canvas untuk capture
    _canvas = html.CanvasElement();
  }

  Future<Uint8List> capture() async {
    if (_video == null || _canvas == null) {
      throw Exception('Camera belum di-initialize');
    }

    // Set ukuran canvas sesuai video
    final width = _video!.videoWidth;
    final height = _video!.videoHeight;

    _canvas!.width = width;
    _canvas!.height = height;

    // Draw video frame ke canvas
    final ctx = _canvas!.context2D;
    ctx.drawImageScaled(_video!, 0, 0, width, height);

    // Convert canvas ke blob
    final blob = await _canvas!.toBlob('image/png');
    
    // Convert blob ke Uint8List
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    
    await reader.onLoad.first;
    
    final result = reader.result as Uint8List;
    return result;
  }

  void dispose() {
    _stream?.getTracks().forEach((track) => track.stop());
    _video?.srcObject = null;
  }
}
