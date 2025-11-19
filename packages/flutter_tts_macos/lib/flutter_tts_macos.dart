import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

/// The macOS implementation of [FlutterTtsPlatform].
class FlutterTtsMacos extends FlutterTtsMethodChannel {
  /// Registers this class as the default instance of [FlutterTtsPlatform]
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsMacos();
  }

  final _macosHostApi = MacosTtsHostApi();

  /// [Future] which sets synthesize to file's future to return
  /// on completion of the synthesize
  Future<ResultDart<TtsResult>> awaitSynthCompletion({
    required bool awaitCompletion,
  }) async {
    try {
      return ResultDart.success(
        await _macosHostApi.awaitSynthCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// getting the speech rate valid range
  Future<ResultDart<TtsRateValidRange>> getSpeechRateValidRange() async {
    try {
      return ResultDart.success(await _macosHostApi.getSpeechRateValidRange());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// setting the language
  /// Macos 10.15 or below does not support Voice selection,
  /// use Language selection instead
  Future<ResultDart<TtsResult>> setLanguange(String language) async {
    try {
      return ResultDart.success(await _macosHostApi.setLanguange(language));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// checking if the language is available, see also [setLanguange]
  Future<ResultDart<bool>> isLanguageAvailable(String language) async {
    try {
      return ResultDart.success(
        await _macosHostApi.isLanguageAvailable(language),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
