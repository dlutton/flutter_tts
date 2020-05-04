import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef void ErrorHandler(dynamic message);
typedef ProgressHandler = void Function(
    String text, int start, int end, String word);

const String iosAudioCategoryOptionsKey = 'iosAudioCategoryOptions';
const String iosAudioCategoryKey = 'iosAudioCategoryKey';
const String iosAudioCategoryAmbientSolo = 'iosAudioCategoryAmbientSolo';
const String iosAudioCategoryAmbient = 'iosAudioCategoryAmbient';
const String iosAudioCategoryPlayback = 'iosAudioCategoryPlayback';
const String iosAudioCategoryPlaybackAndRecord =
    'iosAudioCategoryPlaybackAndRecord';

const String iosAudioCategoryOptionsMixWithOthers =
    'iosAudioCategoryOptionsMixWithOthers';
const String iosAudioCategoryOptionsDuckOthers =
    'iosAudioCategoryOptionsDuckOthers';
const String iosAudioCategoryOptionsInterruptSpokenAudioAndMixWithOthers =
    'iosAudioCategoryOptionsInterruptSpokenAudioAndMixWithOthers';
const String iosAudioCategoryOptionsAllowBluetooth =
    'iosAudioCategoryOptionsAllowBluetooth';
const String iosAudioCategoryOptionsAllowBluetoothA2DP =
    'iosAudioCategoryOptionsAllowBluetoothA2DP';
const String iosAudioCategoryOptionsAllowAirPlay =
    'iosAudioCategoryOptionsAllowAirPlay';
const String iosAudioCategoryOptionsDefaultToSpeaker =
    'iosAudioCategoryOptionsDefaultToSpeaker';

enum TextToSpeechPlatform { android, ios }

enum IosTextToSpeechAudioCategory {
  /// Audio is silenced by screen lock and the silent switch; audio will not mix
  /// with other apps' audio.
  ambientSolo,

  /// Audio is silenced by screen lock and the silent switch; audio will mix
  /// with other apps' (mixable) audio.
  ambient,

  /// Audio is not silenced by screen lock or silent switch; audio will not mix
  /// with other apps' audio.
  ///
  playback,

  ///  The category for recording (input) and playback (output) of audio,
  ///  such as for a Voice over Internet Protocol (VoIP) app.
  /// The default value.
  playAndRecord,
}

enum IosTextToSpeechAudioCategoryOptions {
  /// An option that indicates whether audio from this session mixes with audio
  /// from active sessions in other audio apps.
  mixWithOthers,

  /// An option that reduces the volume of other audio session while audio
  /// from this session plays.
  duckOthers,

  /// An option that determines whether to pause spoken audio content
  /// from other sessions when your app plays its audio.
  interruptSpokenAudioAndMixWithOthers,

  ///An option that determines whether Bluetooth hands-free devices
  /// appear as available input routes.
  allowBluetooth,

  ///An option that determines whether you can stream audio
  /// from this session to Bluetooth devices that support the Advanced Audio Distribution Profile (A2DP).
  allowBluetoothA2DP,

  ///An option that determines whether you can stream audio
  /// from this session to AirPlay devices.
  allowAirPlay,

  ///An option that determines whether audio
  /// from the session defaults to the built-in speaker instead of the receiver.
  /// The default value.
  defaultToSpeaker,
}

class SpeechRateValidRange {
  final double min;
  final double normal;
  final double max;
  final TextToSpeechPlatform platform;

  SpeechRateValidRange(this.min, this.normal, this.max, this.platform);
}

// Provides Platform specific TTS services (Android: TextToSpeech, IOS: AVSpeechSynthesizer)
class FlutterTts {
  static const MethodChannel _channel = const MethodChannel('flutter_tts');

  VoidCallback startHandler;
  VoidCallback completionHandler;
  ProgressHandler progressHandler;
  ErrorHandler errorHandler;

  FlutterTts() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  /// [Future] which invokes the platform specific method for speaking
  Future<dynamic> speak(String text) => _channel.invokeMethod('speak', text);

  /// [Future] which invokes the platform specific method for pause
  /// ***iOS supported only***
  Future<dynamic> pause() => _channel.invokeMethod('pause');

  /// [Future] which invokes the platform specific method for synthesizeToFile
  /// Currently only supported for Android
  Future<dynamic> synthesizeToFile(String text, String fileName) =>
      _channel.invokeMethod('synthesizeToFile', <String, dynamic>{
        "text": text,
        "fileName": fileName,
      });

  /// [Future] which invokes the platform specific method for setLanguage
  Future<dynamic> setLanguage(String language) =>
      _channel.invokeMethod('setLanguage', language);

  /// [Future] which invokes the platform specific method for setSpeechRate
  /// Allowed values are in the range from 0.0 (slowest) to 1.0 (fastest)
  Future<dynamic> setSpeechRate(double rate) =>
      _channel.invokeMethod('setSpeechRate', rate);

  /// [Future] which invokes the platform specific method for setVolume
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<dynamic> setVolume(double volume) =>
      _channel.invokeMethod('setVolume', volume);

  /// [Future] which invokes the platform specific method for shared instance
  /// ***Ios supported only***
  Future<dynamic> setSharedInstance(bool sharedSession) =>
      _channel.invokeMethod('setSharedInstance', sharedSession);

  /// [Future] which invokes the platform specific method for setting audio category
  /// ***Ios supported only***
  Future<dynamic> setIosAudioCategory(IosTextToSpeechAudioCategory category,
      List<IosTextToSpeechAudioCategoryOptions> options) async {
    const Map<IosTextToSpeechAudioCategory, String> categoryToString =
        <IosTextToSpeechAudioCategory, String>{
      IosTextToSpeechAudioCategory.ambientSolo: iosAudioCategoryAmbientSolo,
      IosTextToSpeechAudioCategory.ambient: iosAudioCategoryAmbient,
      IosTextToSpeechAudioCategory.playback: iosAudioCategoryPlayback
    };
    const Map<IosTextToSpeechAudioCategoryOptions, String> optionsToString = {
      IosTextToSpeechAudioCategoryOptions.mixWithOthers:
          'iosAudioCategoryOptionsMixWithOthers',
      IosTextToSpeechAudioCategoryOptions.duckOthers:
          'iosAudioCategoryOptionsDuckOthers',
      IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers:
          'iosAudioCategoryOptionsInterruptSpokenAudioAndMixWithOthers',
      IosTextToSpeechAudioCategoryOptions.allowBluetooth:
          'iosAudioCategoryOptionsAllowBluetooth',
      IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP:
          'iosAudioCategoryOptionsAllowBluetoothA2DP',
      IosTextToSpeechAudioCategoryOptions.allowAirPlay:
          'iosAudioCategoryOptionsAllowAirPlay',
      IosTextToSpeechAudioCategoryOptions.defaultToSpeaker:
          'iosAudioCategoryOptionsDefaultToSpeaker',
    };
    if (!Platform.isAndroid) return;
    try {
      return _channel
          .invokeMethod<dynamic>('setIosAudioCategory', <String, dynamic>{
        iosAudioCategoryKey: categoryToString[category],
        iosAudioCategoryOptionsKey: options.map((o) => optionsToString[o])
      });
    } on PlatformException catch (e) {
      print('setIosAudioCategory error, category: $category');
    }
  }

  /// [Future] which invokes the platform specific method for setPitch
  /// 1.0 is default and ranges from .5 to 2.0
  Future<dynamic> setPitch(double pitch) =>
      _channel.invokeMethod('setPitch', pitch);

  /// [Future] which invokes the platform specific method for setVoice
  /// ***Android supported only***
  Future<dynamic> setVoice(String voice) =>
      _channel.invokeMethod('setVoice', voice);

  /// [Future] which invokes the platform specific method for stop
  Future<dynamic> stop() => _channel.invokeMethod('stop');

  /// [Future] which invokes the platform specific method for getLanguages
  /// Android issues with API 21 & 22
  /// Returns a list of available languages
  Future<dynamic> get getLanguages async {
    final languages = await _channel.invokeMethod('getLanguages');
    return languages;
  }

  /// [Future] which invokes the platform specific method for getVoices
  /// Returns a `List` of voice names
  Future<dynamic> get getVoices async {
    final voices = await _channel.invokeMethod('getVoices');
    return voices;
  }

  /// [Future] which invokes the platform specific method for isLanguageAvailable
  /// Returns `true` or `false`
  Future<dynamic> isLanguageAvailable(String language) =>
      _channel.invokeMethod('isLanguageAvailable', language);

  Future<SpeechRateValidRange> get getSpeechRateValidRange async {
    final validRange = await _channel.invokeMethod('getSpeechRateValidRange')
    as Map<dynamic, dynamic>;
    final min = double.parse(validRange['min'].toString());
    final normal = double.parse(validRange['normal'].toString());
    final max = double.parse(validRange['max'].toString());
    final platformStr = validRange['platform'].toString();
    final platform =
    TextToSpeechPlatform.values.firstWhere((e) =>
    describeEnum(e) == platformStr);

    return SpeechRateValidRange(min, normal, max, platform);
  }

  /// [Future] which invokes the platform specific method for setSilence
  /// 0 means start the utterance immediately. If the value is greater than zero a silence period in milliseconds is set according to the parameter
  Future<dynamic> setSilence(int timems) =>
      _channel.invokeMethod('setSilence', timems ?? 0);

  void setStartHandler(VoidCallback callback) {
    startHandler = callback;
  }

  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }

  void setProgressHandler(ProgressHandler callback) {
    progressHandler = callback;
  }

  void setErrorHandler(ErrorHandler handler) {
    errorHandler = handler;
  }

  /// Platform listeners
  Future platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "speak.onStart":
        if (startHandler != null) {
          startHandler();
        }
        break;
      case "synth.onStart":
        if (startHandler != null) {
          startHandler();
        }
        break;
      case "speak.onComplete":
        if (completionHandler != null) {
          completionHandler();
        }
        break;
      case "synth.onComplete":
        if (completionHandler != null) {
          completionHandler();
        }
        break;
      case "speak.onError":
        if (errorHandler != null) {
          errorHandler(call.arguments);
        }
        break;
      case 'speak.onProgress':
        if (progressHandler != null) {
          final args = call.arguments as Map<dynamic, dynamic>;
          progressHandler(
            args['text'].toString(),
            int.parse(args['start'].toString()),
            int.parse(args['end'].toString()),
            args['word'].toString(),
          );
        }
        break;
      case "synth.onError":
        if (errorHandler != null) {
          errorHandler(call.arguments);
        }
        break;
      default:
        print('Unknowm method ${call.method}');
    }
  }
}
