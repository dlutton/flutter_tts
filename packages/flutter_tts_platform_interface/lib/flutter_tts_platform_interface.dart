import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts_platform_interface/src/flutter_tts_method_channel.dart';
import 'package:flutter_tts_platform_interface/src/messages.g.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

export 'package:flutter_tts_platform_interface/src/flutter_tts_method_channel.dart';
export 'package:flutter_tts_platform_interface/src/flutter_tts_mixin.dart';
export 'package:flutter_tts_platform_interface/src/messages.g.dart';

/// The result type for Flutter TTS platform methods.
typedef ResultDart<T> = Result<T, Exception>;

/// The success type for Flutter TTS platform methods.
typedef SuccessDart<T> = Success<T, Exception>;

/// The error type for Flutter TTS platform methods.
typedef FailureDart<T> = Error<T, Exception>;

/// The abstract class which the platform implementations must extend.
abstract class FlutterTtsPlatform extends PlatformInterface {
  /// constructor
  FlutterTtsPlatform() : super(token: _token);
  static const _token = Object();

  static FlutterTtsPlatform _instance = FlutterTtsMethodChannel();

  /// The default instance of [FlutterTtsPlatform ] to use.
  ///
  /// Defaults to [FlutterTtsMethodChannel].
  static FlutterTtsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTtsPlatform ] when
  /// they register themselves.
  static set instance(FlutterTtsPlatform instance) {
    PlatformInterface.verifyToken(instance, FlutterTtsPlatform._token);
    _instance = instance;
  }

  /// Callbacks for Flutter TTS events.
  /// NOTE: Not all platforms support all callbacks.
  /// on speak start
  VoidCallback? onSpeakStart;

  /// on speak complete
  VoidCallback? onSpeakComplete;

  /// on speak pause
  VoidCallback? onSpeakPause;

  /// on speak resume
  VoidCallback? onSpeakResume;

  /// on speak cancel
  VoidCallback? onSpeakCancel;

  /// on speak error
  ValueChanged<String>? onSpeakError;

  /// on speak progress
  ValueChanged<TtsProgress>? onSpeakProgress;

  /// on synth start
  /// NOTE: Not all platforms support this callback.
  VoidCallback? onSynthStart;

  /// on synth complete
  /// NOTE: Not all platforms support this callback.
  VoidCallback? onSynthComplete;

  /// on synth error
  /// NOTE: Not all platforms support this callback.
  ValueChanged<String>? onSynthError;

  /// on synth progress
  /// NOTE: Not all platforms support this callback.
  ValueChanged<TtsProgress>? onSynthProgress;

  /// [Future] which sets speak's future to return on completion of the utterance
  Future<ResultDart<TtsResult>> awaitSpeakCompletion({
    required bool awaitCompletion,
  }) {
    throw UnimplementedError(
      'awaitSpeakCompletion() has not been implemented.',
    );
  }

  /// [Future] which invokes the platform specific method for speaking
  Future<ResultDart<TtsResult>> speak(String text, {bool focus = false}) {
    throw UnimplementedError('speak() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for pause
  Future<ResultDart<TtsResult>> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for stop
  Future<ResultDart<TtsResult>> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for setSpeechRate
  /// Allowed values are in the range from 0.0 (slowest) to 1.0 (fastest)
  Future<ResultDart<TtsResult>> setSpeechRate(double rate) {
    throw UnimplementedError('setSpeechRate() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for setVolume
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<ResultDart<TtsResult>> setVolume(double volume) {
    throw UnimplementedError('setVolume() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for setPitch
  /// 1.0 is default and ranges from .5 to 2.0
  Future<ResultDart<TtsResult>> setPitch(double pitch) {
    throw UnimplementedError('setPitch() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for getLanguages
  /// Returns a `List` of `Strings` containing the supported languages
  Future<ResultDart<List<String>>> getLanguages() {
    throw UnimplementedError('getLanguages() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for getVoices
  /// Returns a `List` of `Maps` containing a voice name and locale
  /// For iOS specifically, it also includes quality, gender, and identifier
  /// ***Android, iOS, and macOS supported only***
  Future<ResultDart<List<Voice>>> getVoices() {
    throw UnimplementedError('getVoices() has not been implemented.');
  }

  /// [Future] which invokes the platform specific method for setVoice
  Future<ResultDart<TtsResult>> setVoice(Voice voice) {
    throw UnimplementedError('setVoice() has not been implemented.');
  }

  /// [Future] which resets the platform voice to the default
  Future<ResultDart<TtsResult>> clearVoice() {
    throw UnimplementedError('clearVoice() has not been implemented.');
  }
}
