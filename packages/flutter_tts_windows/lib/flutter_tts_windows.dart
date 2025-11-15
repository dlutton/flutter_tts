import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

/// The Windows implementation of [FlutterTtsPlatform].
class FlutterTtsWindows extends FlutterTtsPlatform with FlutterTtsPigeonMixin {
  /// Registers this class as the default instance of [FlutterTtsPlatform]
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsWindows();
  }
}
