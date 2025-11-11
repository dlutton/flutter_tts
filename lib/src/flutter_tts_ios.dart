import 'package:flutter_tts/src/flutter_tts_method_channel.dart';
import 'package:flutter_tts/src/flutter_tts_platform_interface.dart';
import 'package:flutter_tts/src/messages.g.dart';

class FlutterTtsIos extends FlutterTtsMethodChannel {
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsIos();
  }

  final IosTtsHostApi iosHostApi = IosTtsHostApi();

  /// [Future] which sets synthesize to file's future to return on completion of the synthesize
  /// ***Android, iOS, and macOS supported only***
  Future<ResultDart<TtsResult>> awaitSynthCompletion(
    bool awaitCompletion,
  ) async {
    try {
      return ResultDart.success(
        await iosHostApi.awaitSynthCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for synthesizeToFile
  Future<ResultDart<TtsResult>> synthesizeToFile(
    String text,
    String fileName, [
    bool isFullPath = false,
  ]) async {
    try {
      return ResultDart.success(
        await iosHostApi.synthesizeToFile(text, fileName, isFullPath),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for shared instance
  /// ***iOS supported only***
  Future<ResultDart<TtsResult>> setSharedInstance(bool sharedSession) async {
    try {
      return ResultDart.success(
        await iosHostApi.setSharedInstance(sharedSession),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setting the autoStopSharedSession
  /// default value is true
  /// *** iOS, and macOS supported only***
  Future<ResultDart<TtsResult>> autoStopSharedSession(bool autoStop) async {
    try {
      return ResultDart.success(
        await iosHostApi.autoStopSharedSession(autoStop),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setting audio category
  /// ***Ios supported only***
  Future<ResultDart<TtsResult>> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, {
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  }) async {
    try {
      return ResultDart.success(
        await iosHostApi.setIosAudioCategory(category, options, mode: mode),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  Future<ResultDart<TtsRateValidRange>> getSpeechRateValidRange() async {
    try {
      return ResultDart.success(await iosHostApi.getSpeechRateValidRange());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for isLanguageAvailable
  /// Returns `true` or `false`
  Future<ResultDart<bool>> isLanguageAvailable(String language) async {
    try {
      return ResultDart.success(await iosHostApi.isLanguageAvailable(language));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  Future<ResultDart<TtsResult>> setLanguange(String language) async {
    try {
      return ResultDart.success(await iosHostApi.setLanguange(language));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
