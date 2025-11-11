import 'package:flutter_tts/src/flutter_tts_method_channel.dart';
import 'package:flutter_tts/src/flutter_tts_platform_interface.dart';
import 'package:flutter_tts/src/messages.g.dart';

class FlutterTtsAndroid extends FlutterTtsMethodChannel {
  static void registerWith() {
    FlutterTtsPlatform.instance = FlutterTtsAndroid();
  }

  final androidHostApi = AndroidTtsHostApi();

  /// [Future] which sets synthesize to file's future to return on completion of the synthesize
  /// ***Android, iOS, and macOS supported only***
  Future<ResultDart<TtsResult>> awaitSynthCompletion(
    bool awaitCompletion,
  ) async {
    try {
      return ResultDart.success(
        await androidHostApi.awaitSynthCompletion(awaitCompletion),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getMaxSpeechInputLength
  /// ***Android supported only***
  Future<ResultDart<int?>> getMaxSpeechInputLength() async {
    try {
      return ResultDart.success(await androidHostApi.getMaxSpeechInputLength());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setEngine
  /// ***Android supported only***
  Future<ResultDart<TtsResult>> setEngine(String engine) async {
    try {
      return ResultDart.success(await androidHostApi.setEngine(engine));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getEngines
  /// Returns a list of installed TTS engines
  /// ***Android supported only***
  Future<ResultDart<List<String>>> getEngines() async {
    try {
      return ResultDart.success(await androidHostApi.getEngines());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getDefaultEngine
  /// Returns a `String` of the default engine name
  /// ***Android supported only ***
  Future<ResultDart<String?>> getDefaultEngine() async {
    try {
      return ResultDart.success(await androidHostApi.getDefaultEngine());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getDefaultVoice
  /// Returns a `Map` containing a voice name and locale
  /// ***Android supported only ***
  Future<ResultDart<Voice?>> getDefaultVoice() async {
    try {
      return ResultDart.success(await androidHostApi.getDefaultVoice());
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
        await androidHostApi.synthesizeToFile(text, fileName, isFullPath),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for isLanguageInstalled
  /// Returns `true` or `false`
  /// ***Android supported only***
  Future<ResultDart<bool>> isLanguageInstalled(String language) async {
    try {
      return ResultDart.success(
        await androidHostApi.isLanguageInstalled(language),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for isLanguageAvailable
  /// Returns `true` or `false`
  Future<ResultDart<bool>> isLanguageAvailable(String language) async {
    try {
      return ResultDart.success(
        await androidHostApi.isLanguageAvailable(language),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for areLanguagesInstalled
  /// Returns a HashMap with `true` or `false` for each submitted language.
  /// ***Android supported only***
  Future<ResultDart<Map<String, bool>>> areLanguagesInstalled(
    List<String> languages,
  ) async {
    try {
      return ResultDart.success(
        await androidHostApi.areLanguagesInstalled(languages),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for getSpeechRateValidRange
  /// Returns a `SpeechRateValidRange` object containing the minimum, normal, and maximum speech rate values for the current platform.
  /// ***Android supported only***
  Future<ResultDart<TtsRateValidRange>> getSpeechRateValidRange() async {
    try {
      return ResultDart.success(await androidHostApi.getSpeechRateValidRange());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setSilence
  /// 0 means start the utterance immediately. If the value is greater than zero a silence period in milliseconds is set according to the parameter
  /// ***Android supported only***
  Future<ResultDart<TtsResult>> setSilence(int timems) async {
    try {
      return ResultDart.success(await androidHostApi.setSilence(timems));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setQueueMode
  /// 0 means QUEUE_FLUSH - Queue mode where all entries in the playback queue (media to be played and text to be synthesized) are dropped and replaced by the new entry.
  /// Queues are flushed with respect to a given calling app. Entries in the queue from other calls are not discarded.
  /// 1 means QUEUE_ADD - Queue mode where the new entry is added at the end of the playback queue.
  /// ***Android supported only***
  Future<ResultDart<TtsResult>> setQueueMode(int queueMode) async {
    try {
      return ResultDart.success(await androidHostApi.setQueueMode(queueMode));
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// [Future] which invokes the platform specific method for setAudioAttributesForNavigation
  /// ***Android supported only***
  Future<ResultDart<TtsResult>> setAudioAttributesForNavigation() async {
    try {
      return ResultDart.success(
        await androidHostApi.setAudioAttributesForNavigation(),
      );
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }
}
