import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

/// The Windows implementation of [FlutterTtsPlatform].
class FlutterTtsWindows extends FlutterTtsPlatform with FlutterTtsPigeonMixin {
  /// Registers this class as the default instance of [FlutterTtsPlatform]
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsWindows();
  }

  final _winHostApi = WinTtsHostApi();

  /// Set the boundary type for the TTS engine. Word boundary by default
  ///
  /// [isWordBoundary] word boundary if true, else sentence boundary.
  Future<ResultDart<TtsResult>> setBoundaryType({
    required bool isWordBoundary,
  }) async {
    try {
      final result = await _winHostApi.setBoundaryType(isWordBoundary);
      return SuccessDart(result);
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
