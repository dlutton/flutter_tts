import 'package:flutter_tts/src/flutter_tts_method_channel.dart';
import 'package:flutter_tts/src/flutter_tts_platform_interface.dart';
import 'package:flutter_tts/src/messages.g.dart';

class FlutterTtsMacos extends FlutterTtsMethodChannel {
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsMacos();
  }

  final macosHostApi = MacosTtsHostApi();

  /// [Future] which sets synthesize to file's future to return on completion of the synthesize
  /// ***Android, iOS, and macOS supported only***
  Future<ResultDart<TtsResult>> awaitSynthCompletion(
    bool awaitCompletion,
  ) async {
    try {
      return ResultDart.success(
        await macosHostApi.awaitSynthCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getting the speech rate valid range
  /// ***iOS, and macOS supported only***
  Future<ResultDart<TtsRateValidRange>> getSpeechRateValidRange() async {
    try {
      return ResultDart.success(await macosHostApi.getSpeechRateValidRange());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  Future<ResultDart<TtsResult>> setLanguange(String language) async {
    try {
      return ResultDart.success(await macosHostApi.setLanguange(language));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  Future<ResultDart<bool>> isLanguageAvailable(String language) async {
    try {
      return ResultDart.success(
        await macosHostApi.isLanguageAvailable(language),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
