import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/src/flutter_tts_method_channel.dart';
import 'package:flutter_tts/src/messages.g.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

typedef ResultDart<T> = Result<T, Exception>;
typedef SuccessDart<T> = Success<T, Exception>;
typedef FailureDart<T> = Error<T, Exception>;

abstract class FlutterTtsPlatform extends PlatformInterface {
  static const token = Object();

  static FlutterTtsPlatform _instance = FlutterTtsMethodChannel();

  /// The default instance of [FlutterTtsPlatform ] to use.
  ///
  /// Defaults to [MethodChannelFlutterSysFonts].
  static FlutterTtsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTtsPlatform ] when
  /// they register themselves.
  static set instance(FlutterTtsPlatform instance) {
    PlatformInterface.verifyToken(instance, FlutterTtsPlatform.token);
    _instance = instance;
  }

  VoidCallback? onSpeakStart;
  VoidCallback? onSpeakComplete;
  VoidCallback? onSpeakPause;
  VoidCallback? onSpeakResume;
  VoidCallback? onSpeakCancel;
  ValueChanged<String>? onSpeakError;
  ValueChanged<TtsProgress>? onSpeakProgress;

  VoidCallback? onSynthStart;
  VoidCallback? onSynthComplete;
  ValueChanged<String>? onSynthError;

  FlutterTtsPlatform() : super(token: token);

  /// [Future] which sets speak's future to return on completion of the utterance
  Future<ResultDart<TtsResult>> awaitSpeakCompletion(bool awaitCompletion);

  /// [Future] which invokes the platform specific method for speaking
  Future<ResultDart<TtsResult>> speak(String text, {bool focus = false});

  /// [Future] which invokes the platform specific method for pause
  Future<ResultDart<TtsResult>> pause();

  /// [Future] which invokes the platform specific method for stop
  Future<ResultDart<TtsResult>> stop();

  /// [Future] which invokes the platform specific method for setSpeechRate
  /// Allowed values are in the range from 0.0 (slowest) to 1.0 (fastest)
  Future<ResultDart<TtsResult>> setSpeechRate(double rate);

  /// [Future] which invokes the platform specific method for setVolume
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<ResultDart<TtsResult>> setVolume(double volume);

  /// [Future] which invokes the platform specific method for setPitch
  /// 1.0 is default and ranges from .5 to 2.0
  Future<ResultDart<TtsResult>> setPitch(double pitch);

  Future<ResultDart<List<String>>> getLanguages();

  /// [Future] which invokes the platform specific method for getVoices
  /// Returns a `List` of `Maps` containing a voice name and locale
  /// For iOS specifically, it also includes quality, gender, and identifier
  /// ***Android, iOS, and macOS supported only***
  Future<ResultDart<List<Voice>>> getVoices();

  /// [Future] which invokes the platform specific method for setVoice
  Future<ResultDart<TtsResult>> setVoice(Voice voice);

  /// [Future] which resets the platform voice to the default
  Future<ResultDart<TtsResult>> clearVoice();
}
