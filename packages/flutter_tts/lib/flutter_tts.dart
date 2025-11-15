import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

export 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

/// app facing class
abstract class FlutterTts {
  /// get the instance of FlutterTtsPlatform
  static FlutterTtsPlatform get platform => FlutterTtsPlatform.instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTtsPlatform ] when
  /// they register themselves.
  static set platform(FlutterTtsPlatform instance) {
    FlutterTtsPlatform.instance = instance;
  }
}
