// Stub untuk platform non-web (mobile)
import 'dart:typed_data';

class WebCamera {
  Future<void> initialize() async {
    throw UnsupportedError('WebCamera only works on web platform');
  }

  Future<Uint8List> capture() async {
    throw UnsupportedError('WebCamera only works on web platform');
  }

  void dispose() {
    // No-op on mobile
  }
}
