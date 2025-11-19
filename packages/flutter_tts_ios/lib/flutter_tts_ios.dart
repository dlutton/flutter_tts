import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';

/// The iOS implementation of [FlutterTtsPlatform].
class FlutterTtsIos extends FlutterTtsPlatform with FlutterTtsPigeonMixin {
  /// Registers this class as the default instance of [FlutterTtsPlatform]
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsIos();
  }

  final IosTtsHostApi _iosHostApi = IosTtsHostApi();

  /// [Future] which sets synthesize to file's future to return
  /// on completion of the synthesize
  Future<ResultDart<TtsResult>> awaitSynthCompletion({
    required bool awaitCompletion,
  }) async {
    try {
      return ResultDart.success(
        await _iosHostApi.awaitSynthCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for synthesizeToFile
  Future<ResultDart<TtsResult>> synthesizeToFile(
    String text,
    String fileName, {
    bool isFullPath = false,
  }) async {
    try {
      ensureSetupTtsCallback();
      return ResultDart.success(
        await _iosHostApi.synthesizeToFile(text, fileName, isFullPath),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for shared instance
  /// ***iOS supported only***
  Future<ResultDart<TtsResult>> setSharedInstance({
    required bool sharedSession,
  }) async {
    try {
      return ResultDart.success(
        await _iosHostApi.setSharedInstance(sharedSession),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// setting the autoStopSharedSession, default value is true
  Future<ResultDart<TtsResult>> autoStopSharedSession({
    required bool autoStop,
  }) async {
    try {
      return ResultDart.success(
        await _iosHostApi.autoStopSharedSession(autoStop),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method
  /// for setting audio category
  Future<ResultDart<TtsResult>> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, {
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  }) async {
    try {
      return ResultDart.success(
        await _iosHostApi.setIosAudioCategory(category, options, mode: mode),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// getting the speech rate valid range
  Future<ResultDart<TtsRateValidRange>> getSpeechRateValidRange() async {
    try {
      return ResultDart.success(await _iosHostApi.getSpeechRateValidRange());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// checking if the language is available, see also [setLanguange]
  Future<ResultDart<bool>> isLanguageAvailable(String language) async {
    try {
      return ResultDart.success(
        await _iosHostApi.isLanguageAvailable(language),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for
  /// setting the language
  /// Ios 9.0 or below does not support Voice selection,
  /// use Language selection instead
  Future<ResultDart<TtsResult>> setLanguange(String language) async {
    try {
      return ResultDart.success(await _iosHostApi.setLanguange(language));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
