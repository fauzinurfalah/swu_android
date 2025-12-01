import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebCamera {

  WebCamera._internal() {
    _registerViewFactoryOnce();
  }
  static final WebCamera _instance = WebCamera._internal();
  factory WebCamera() => _instance;

  static const String viewType = 'webcam-view';
  static bool _viewRegistered = false;

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

    _canvas!
      ..width = width
      ..height = height;

    final ctx = _canvas!.context2D;
    ctx.drawImageScaled(_video!, 0, 0, width, height);

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
}
