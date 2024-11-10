import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

typedef ErrorHandler = void Function(dynamic message);
typedef ProgressHandler = void Function(
    String text, int start, int end, String word);

const String iosAudioCategoryOptionsKey = 'iosAudioCategoryOptionsKey';
const String iosAudioCategoryKey = 'iosAudioCategoryKey';
const String iosAudioModeKey = 'iosAudioModeKey';
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

const String iosAudioModeDefault = 'iosAudioModeDefault';
const String iosAudioModeGameChat = 'iosAudioModeGameChat';
const String iosAudioModeMeasurement = 'iosAudioModeMeasurement';
const String iosAudioModeMoviePlayback = 'iosAudioModeMoviePlayback';
const String iosAudioModeSpokenAudio = 'iosAudioModeSpokenAudio';
const String iosAudioModeVideoChat = 'iosAudioModeVideoChat';
const String iosAudioModeVideoRecording = 'iosAudioModeVideoRecording';
const String iosAudioModeVoiceChat = 'iosAudioModeVoiceChat';
const String iosAudioModeVoicePrompt = 'iosAudioModeVoicePrompt';

enum TextToSpeechPlatform { android, ios }

/// Audio session category identifiers for iOS.
///
/// See also:
/// * https://developer.apple.com/documentation/avfaudio/avaudiosession/category
enum IosTextToSpeechAudioCategory {
  /// The default audio session category.
  ///
  /// Your audio is silenced by screen locking and by the Silent switch.
  ///
  /// By default, using this category implies that your app’s audio
  /// is nonmixable—activating your session will interrupt
  /// any other audio sessions which are also nonmixable.
  /// To allow mixing, use the [ambient] category instead.
  ambientSolo,

  /// The category for an app in which sound playback is nonprimary — that is,
  /// your app also works with the sound turned off.
  ///
  /// This category is also appropriate for “play-along” apps,
  /// such as a virtual piano that a user plays while the Music app is playing.
  /// When you use this category, audio from other apps mixes with your audio.
  /// Screen locking and the Silent switch (on iPhone, the Ring/Silent switch) silence your audio.
  ambient,

  /// The category for playing recorded music or other sounds
  /// that are central to the successful use of your app.
  ///
  /// When using this category, your app audio continues
  /// with the Silent switch set to silent or when the screen locks.
  ///
  /// By default, using this category implies that your app’s audio
  /// is nonmixable—activating your session will interrupt
  /// any other audio sessions which are also nonmixable.
  /// To allow mixing for this category, use the
  /// [IosTextToSpeechAudioCategoryOptions.mixWithOthers] option.
  playback,

  /// The category for recording (input) and playback (output) of audio,
  /// such as for a Voice over Internet Protocol (VoIP) app.
  ///
  /// Your audio continues with the Silent switch set to silent and with the screen locked.
  /// This category is appropriate for simultaneous recording and playback,
  /// and also for apps that record and play back, but not simultaneously.
  playAndRecord,
}

/// Audio session mode identifiers for iOS.
///
/// See also:
/// * https://developer.apple.com/documentation/avfaudio/avaudiosession/mode
enum IosTextToSpeechAudioMode {
  /// The default audio session mode.
  ///
  /// You can use this mode with every [IosTextToSpeechAudioCategory].
  defaultMode,

  /// A mode that the GameKit framework sets on behalf of an application
  /// that uses GameKit’s voice chat service.
  ///
  /// This mode is valid only with the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  ///
  /// Don’t set this mode directly. If you need similar behavior and aren’t
  /// using a `GKVoiceChat` object, use [voiceChat] or [videoChat] instead.
  gameChat,

  /// A mode that indicates that your app is performing measurement of audio input or output.
  ///
  /// Use this mode for apps that need to minimize the amount of
  /// system-supplied signal processing to input and output signals.
  /// If recording on devices with more than one built-in microphone,
  /// the session uses the primary microphone.
  ///
  /// For use with the [IosTextToSpeechAudioCategory.playback] or
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  ///
  /// **Important:** This mode disables some dynamics processing on input and output signals,
  /// resulting in a lower-output playback level.
  measurement,

  /// A mode that indicates that your app is playing back movie content.
  ///
  /// When you set this mode, the audio session uses signal processing to enhance
  /// movie playback for certain audio routes such as built-in speaker or headphones.
  /// You may only use this mode with the
  /// [IosTextToSpeechAudioCategory.playback] category.
  moviePlayback,

  /// A mode used for continuous spoken audio to pause the audio when another app plays a short audio prompt.
  ///
  /// This mode is appropriate for apps that play continuous spoken audio,
  /// such as podcasts or audio books. Setting this mode indicates that your app
  /// should pause, rather than duck, its audio if another app plays
  /// a spoken audio prompt. After the interrupting app’s audio ends, you can
  /// resume your app’s audio playback.
  spokenAudio,

  /// A mode that indicates that your app is engaging in online video conferencing.
  ///
  /// Use this mode for video chat apps that use the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  /// When you set this mode, the audio session optimizes the device’s tonal
  /// equalization for voice. It also reduces the set of allowable audio routes
  /// to only those appropriate for video chat.
  ///
  /// Using this mode has the side effect of enabling the
  /// [IosTextToSpeechAudioCategoryOptions.allowBluetooth] category option.
  videoChat,

  /// A mode that indicates that your app is recording a movie.
  ///
  /// This mode is valid only with the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  /// On devices with more than one built-in microphone,
  /// the audio session uses the microphone closest to the video camera.
  ///
  /// Use this mode to ensure that the system provides appropriate audio-signal processing.
  videoRecording,

  /// A mode that indicates that your app is performing two-way voice communication,
  /// such as using Voice over Internet Protocol (VoIP).
  ///
  /// Use this mode for Voice over IP (VoIP) apps that use the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  /// When you set this mode, the session optimizes the device’s tonal
  /// equalization for voice and reduces the set of allowable audio routes
  /// to only those appropriate for voice chat.
  ///
  /// Using this mode has the side effect of enabling the
  /// [IosTextToSpeechAudioCategoryOptions.allowBluetooth] category option.
  voiceChat,

  /// A mode that indicates that your app plays audio using text-to-speech.
  ///
  /// Setting this mode allows for different routing behaviors when your app
  /// is connected to certain audio devices, such as CarPlay.
  /// An example of an app that uses this mode is a turn-by-turn navigation app
  /// that plays short prompts to the user.
  ///
  /// Typically, apps of the same type also configure their sessions to use the
  /// [IosTextToSpeechAudioCategoryOptions.duckOthers] and
  /// [IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers] options.
  voicePrompt,
}

/// Audio session category options for iOS.
///
/// See also:
/// * https://developer.apple.com/documentation/avfaudio/avaudiosession/categoryoptions
enum IosTextToSpeechAudioCategoryOptions {
  /// An option that indicates whether audio from this session mixes with audio
  /// from active sessions in other audio apps.
  ///
  /// You can set this option explicitly only if the audio session category
  /// is [IosTextToSpeechAudioCategory.playAndRecord] or
  /// [IosTextToSpeechAudioCategory.playback].
  /// If you set the audio session category to [IosTextToSpeechAudioCategory.ambient],
  /// the session automatically sets this option.
  /// Likewise, setting the [duckOthers] or [interruptSpokenAudioAndMixWithOthers]
  /// options also enables this option.
  ///
  /// If you set this option, your app mixes its audio with audio playing
  /// in background apps, such as the Music app.
  mixWithOthers,

  /// An option that reduces the volume of other audio sessions while audio
  /// from this session plays.
  ///
  /// You can set this option only if the audio session category is
  /// [IosTextToSpeechAudioCategory.playAndRecord] or
  /// [IosTextToSpeechAudioCategory.playback].
  /// Setting it implicitly sets the [mixWithOthers] option.
  ///
  /// Use this option to mix your app’s audio with that of others.
  /// While your app plays its audio, the system reduces the volume of other
  /// audio sessions to make yours more prominent. If your app provides
  /// occasional spoken audio, such as in a turn-by-turn navigation app
  /// or an exercise app, you should also set the [interruptSpokenAudioAndMixWithOthers] option.
  ///
  /// Note that ducking begins when you activate your app’s audio session
  /// and ends when you deactivate the session.
  ///
  /// See also:
  /// * [FlutterTts.setSharedInstance]
  duckOthers,

  /// An option that determines whether to pause spoken audio content
  /// from other sessions when your app plays its audio.
  ///
  /// You can set this option only if the audio session category is
  /// [IosTextToSpeechAudioCategory.playAndRecord] or
  /// [IosTextToSpeechAudioCategory.playback].
  /// Setting this option also sets [mixWithOthers].
  ///
  /// If you set this option, the system mixes your audio with other
  /// audio sessions, but interrupts (and stops) audio sessions that use the
  /// [IosTextToSpeechAudioMode.spokenAudio] audio session mode.
  /// It pauses the audio from other apps as long as your session is active.
  /// After your audio session deactivates, the system resumes the interrupted app’s audio.
  ///
  /// Set this option if your app’s audio is occasional and spoken,
  /// such as in a turn-by-turn navigation app or an exercise app.
  /// This avoids intelligibility problems when two spoken audio apps mix.
  /// If you set this option, also set the [duckOthers] option unless
  /// you have a specific reason not to. Ducking other audio, rather than
  /// interrupting it, is appropriate when the other audio isn’t spoken audio.
  interruptSpokenAudioAndMixWithOthers,

  /// An option that determines whether Bluetooth hands-free devices appear
  /// as available input routes.
  ///
  /// You can set this option only if the audio session category is
  /// [IosTextToSpeechAudioCategory.playAndRecord] or
  /// [IosTextToSpeechAudioCategory.playback].
  ///
  /// You’re required to set this option to allow routing audio input and output
  /// to a paired Bluetooth Hands-Free Profile (HFP) device.
  /// If you clear this option, paired Bluetooth HFP devices don’t show up
  /// as available audio input routes.
  allowBluetooth,

  /// An option that determines whether you can stream audio from this session
  /// to Bluetooth devices that support the Advanced Audio Distribution Profile (A2DP).
  ///
  /// A2DP is a stereo, output-only profile intended for higher bandwidth
  /// audio use cases, such as music playback.
  /// The system automatically routes to A2DP ports if you configure an
  /// app’s audio session to use the [IosTextToSpeechAudioCategory.ambient],
  /// [IosTextToSpeechAudioCategory.ambientSolo], or
  /// [IosTextToSpeechAudioCategory.playback] categories.
  ///
  /// Starting with iOS 10.0, apps using the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category may also allow
  /// routing output to paired Bluetooth A2DP devices. To enable this behavior,
  /// pass this category option when setting your audio session’s category.
  ///
  /// Note: If this option and the [allowBluetooth] option are both set,
  /// when a single device supports both the Hands-Free Profile (HFP) and A2DP,
  /// the system gives hands-free ports a higher priority for routing.
  allowBluetoothA2DP,

  /// An option that determines whether you can stream audio
  /// from this session to AirPlay devices.
  ///
  /// Setting this option enables the audio session to route audio output
  /// to AirPlay devices. You can only explicitly set this option if the
  /// audio session’s category is set to [IosTextToSpeechAudioCategory.playAndRecord].
  /// For most other audio session categories, the system sets this option implicitly.
  allowAirPlay,

  /// An option that determines whether audio from the session defaults to the built-in speaker instead of the receiver.
  ///
  /// You can set this option only when using the
  /// [IosTextToSpeechAudioCategory.playAndRecord] category.
  /// It’s used to modify the category’s routing behavior so that audio
  /// is always routed to the speaker rather than the receiver if
  /// no other accessories, such as headphones, are in use.
  ///
  /// When using this option, the system honors user gestures.
  /// For example, plugging in a headset causes the route to change to
  /// headset mic/headphones, and unplugging the headset causes the route
  /// to change to built-in mic/speaker (as opposed to built-in mic/receiver)
  /// when you’ve set this override.
  ///
  /// In the case of using a USB input-only accessory, audio input
  /// comes from the accessory, and the system routes audio to the headphones,
  /// if attached, or to the speaker if the headphones aren’t plugged in.
  /// The use case is to route audio to the speaker instead of the receiver
  /// in cases where the audio would normally go to the receiver.
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
  static const MethodChannel _channel = MethodChannel('flutter_tts');

  VoidCallback? startHandler;
  VoidCallback? completionHandler;
  VoidCallback? pauseHandler;
  VoidCallback? continueHandler;
  VoidCallback? cancelHandler;
  ProgressHandler? progressHandler;
  ErrorHandler? errorHandler;

  FlutterTts() {
    _channel.setMethodCallHandler(platformCallHandler);
  }

  /// [Future] which sets speak's future to return on completion of the utterance
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async =>
      await _channel.invokeMethod('awaitSpeakCompletion', awaitCompletion);

  /// [Future] which sets synthesize to file's future to return on completion of the synthesize
  /// ***Android, iOS, and macOS supported only***
  Future<dynamic> awaitSynthCompletion(bool awaitCompletion) async =>
      await _channel.invokeMethod('awaitSynthCompletion', awaitCompletion);

  /// [Future] which invokes the platform specific method for speaking
  Future<dynamic> speak(String text, {bool focus = false}) async {
    if (!kIsWeb && Platform.isAndroid) {
      return await _channel.invokeMethod('speak', <String, dynamic>{
        "text": text,
        "focus": focus,
      });
    } else {
      return await _channel.invokeMethod('speak', text);
    }
  }

  /// [Future] which invokes the platform specific method for pause
  Future<dynamic> pause() async => await _channel.invokeMethod('pause');

  /// [Future] which invokes the platform specific method for getMaxSpeechInputLength
  /// ***Android supported only***
  Future<int?> get getMaxSpeechInputLength async {
    return await _channel.invokeMethod<int?>('getMaxSpeechInputLength');
  }

  /// [Future] which invokes the platform specific method for synthesizeToFile
  /// ***Android and iOS supported only***
  Future<dynamic> synthesizeToFile(String text, String fileName,
          [bool isFullPath = false]) async =>
      _channel.invokeMethod('synthesizeToFile', <String, dynamic>{
        "text": text,
        "fileName": fileName,
        "isFullPath": isFullPath,
      });

  /// [Future] which invokes the platform specific method for setLanguage
  Future<dynamic> setLanguage(String language) async =>
      await _channel.invokeMethod('setLanguage', language);

  /// [Future] which invokes the platform specific method for setSpeechRate
  /// Allowed values are in the range from 0.0 (slowest) to 1.0 (fastest)
  Future<dynamic> setSpeechRate(double rate) async =>
      await _channel.invokeMethod('setSpeechRate', rate);

  /// [Future] which invokes the platform specific method for setVolume
  /// Allowed values are in the range from 0.0 (silent) to 1.0 (loudest)
  Future<dynamic> setVolume(double volume) async =>
      await _channel.invokeMethod('setVolume', volume);

  /// [Future] which invokes the platform specific method for shared instance
  /// ***iOS supported only***
  Future<dynamic> setSharedInstance(bool sharedSession) async =>
      await _channel.invokeMethod('setSharedInstance', sharedSession);

  /// [Future] which invokes the platform specific method for setting the autoStopSharedSession
  /// default value is true
  /// *** iOS, and macOS supported only***
  Future<dynamic> autoStopSharedSession(bool autoStop) async =>
      await _channel.invokeMethod('autoStopSharedSession', autoStop);

  /// [Future] which invokes the platform specific method for setting audio category
  /// ***Ios supported only***
  Future<dynamic> setIosAudioCategory(IosTextToSpeechAudioCategory category,
      List<IosTextToSpeechAudioCategoryOptions> options,
      [IosTextToSpeechAudioMode mode =
          IosTextToSpeechAudioMode.defaultMode]) async {
    const categoryToString = <IosTextToSpeechAudioCategory, String>{
      IosTextToSpeechAudioCategory.ambientSolo: iosAudioCategoryAmbientSolo,
      IosTextToSpeechAudioCategory.ambient: iosAudioCategoryAmbient,
      IosTextToSpeechAudioCategory.playback: iosAudioCategoryPlayback
    };
    const optionsToString = {
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
    const modeToString = <IosTextToSpeechAudioMode, String>{
      IosTextToSpeechAudioMode.defaultMode: iosAudioModeDefault,
      IosTextToSpeechAudioMode.gameChat: iosAudioModeGameChat,
      IosTextToSpeechAudioMode.measurement: iosAudioModeMeasurement,
      IosTextToSpeechAudioMode.moviePlayback: iosAudioModeMoviePlayback,
      IosTextToSpeechAudioMode.spokenAudio: iosAudioModeSpokenAudio,
      IosTextToSpeechAudioMode.videoChat: iosAudioModeVideoChat,
      IosTextToSpeechAudioMode.videoRecording: iosAudioModeVideoRecording,
      IosTextToSpeechAudioMode.voiceChat: iosAudioModeVoiceChat,
      IosTextToSpeechAudioMode.voicePrompt: iosAudioModeVoicePrompt,
    };
    if (!Platform.isIOS) return;
    try {
      return await _channel
          .invokeMethod<dynamic>('setIosAudioCategory', <String, dynamic>{
        iosAudioCategoryKey: categoryToString[category],
        iosAudioCategoryOptionsKey:
            options.map((o) => optionsToString[o]).toList(),
        iosAudioModeKey: modeToString[mode],
      });
    } on PlatformException catch (e) {
      print(
          'setIosAudioCategory error, category: $category, mode: $mode, error: ${e.message}');
    }
  }

  /// [Future] which invokes the platform specific method for setEngine
  /// ***Android supported only***
  Future<dynamic> setEngine(String engine) async {
    await _channel.invokeMethod('setEngine', engine);
  }

  /// [Future] which invokes the platform specific method for setPitch
  /// 1.0 is default and ranges from .5 to 2.0
  Future<dynamic> setPitch(double pitch) async =>
      await _channel.invokeMethod('setPitch', pitch);

  /// [Future] which invokes the platform specific method for setVoice
  /// ***Android, iOS, and macOS supported only***
  Future<dynamic> setVoice(Map<String, String> voice) async =>
      await _channel.invokeMethod('setVoice', voice);

  /// [Future] which resets the platform voice to the default
  Future<dynamic> clearVoice() async =>
      await _channel.invokeMethod('clearVoice');

  /// [Future] which invokes the platform specific method for stop
  Future<dynamic> stop() async => await _channel.invokeMethod('stop');

  /// [Future] which invokes the platform specific method for getLanguages
  /// Android issues with API 21 & 22
  /// Returns a list of available languages
  Future<dynamic> get getLanguages async {
    final languages = await _channel.invokeMethod('getLanguages');
    return languages;
  }

  /// [Future] which invokes the platform specific method for getEngines
  /// Returns a list of installed TTS engines
  /// ***Android supported only***
  Future<dynamic> get getEngines async {
    final engines = await _channel.invokeMethod('getEngines');
    return engines;
  }

  /// [Future] which invokes the platform specific method for getDefaultEngine
  /// Returns a `String` of the default engine name
  /// ***Android supported only ***
  Future<dynamic> get getDefaultEngine async {
    final engineName = await _channel.invokeMethod('getDefaultEngine');
    return engineName;
  }

  /// [Future] which invokes the platform specific method for getDefaultVoice
  /// Returns a `Map` containing a voice name and locale
  /// ***Android supported only ***
  Future<dynamic> get getDefaultVoice async {
    final voice = await _channel.invokeMethod('getDefaultVoice');
    return voice;
  }

  /// [Future] which invokes the platform specific method for getVoices
  /// Returns a `List` of `Maps` containing a voice name and locale
  /// For iOS specifically, it also includes quality, gender, and identifier
  /// ***Android, iOS, and macOS supported only***
  Future<dynamic> get getVoices async {
    final voices = await _channel.invokeMethod('getVoices');
    return voices;
  }

  /// [Future] which invokes the platform specific method for isLanguageAvailable
  /// Returns `true` or `false`
  Future<dynamic> isLanguageAvailable(String language) async =>
      await _channel.invokeMethod('isLanguageAvailable', language);

  /// [Future] which invokes the platform specific method for isLanguageInstalled
  /// Returns `true` or `false`
  /// ***Android supported only***
  Future<dynamic> isLanguageInstalled(String language) async =>
      await _channel.invokeMethod('isLanguageInstalled', language);

  /// [Future] which invokes the platform specific method for areLanguagesInstalled
  /// Returns a HashMap with `true` or `false` for each submitted language.
  /// ***Android supported only***
  Future<dynamic> areLanguagesInstalled(List<String> languages) async =>
      await _channel.invokeMethod('areLanguagesInstalled', languages);

  Future<SpeechRateValidRange> get getSpeechRateValidRange async {
    final validRange = await _channel.invokeMethod('getSpeechRateValidRange')
        as Map<dynamic, dynamic>;
    final min = double.parse(validRange['min'].toString());
    final normal = double.parse(validRange['normal'].toString());
    final max = double.parse(validRange['max'].toString());
    final platformStr = validRange['platform'].toString();
    final platform =
        TextToSpeechPlatform.values.firstWhere((e) => e.name == platformStr);

    return SpeechRateValidRange(min, normal, max, platform);
  }

  /// [Future] which invokes the platform specific method for setSilence
  /// 0 means start the utterance immediately. If the value is greater than zero a silence period in milliseconds is set according to the parameter
  /// ***Android supported only***
  Future<dynamic> setSilence(int timems) async =>
      await _channel.invokeMethod('setSilence', timems);

  /// [Future] which invokes the platform specific method for setQueueMode
  /// 0 means QUEUE_FLUSH - Queue mode where all entries in the playback queue (media to be played and text to be synthesized) are dropped and replaced by the new entry.
  /// Queues are flushed with respect to a given calling app. Entries in the queue from other calls are not discarded.
  /// 1 means QUEUE_ADD - Queue mode where the new entry is added at the end of the playback queue.
  /// ***Android supported only***
  Future<dynamic> setQueueMode(int queueMode) async =>
      await _channel.invokeMethod('setQueueMode', queueMode);

  void setStartHandler(VoidCallback callback) {
    startHandler = callback;
  }

  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }

  void setContinueHandler(VoidCallback callback) {
    continueHandler = callback;
  }

  void setPauseHandler(VoidCallback callback) {
    pauseHandler = callback;
  }

  void setCancelHandler(VoidCallback callback) {
    cancelHandler = callback;
  }

  void setProgressHandler(ProgressHandler callback) {
    progressHandler = callback;
  }

  void setErrorHandler(ErrorHandler handler) {
    errorHandler = handler;
  }

  /// Platform listeners
  Future<dynamic> platformCallHandler(MethodCall call) async {
    switch (call.method) {
      case "speak.onStart":
        if (startHandler != null) {
          startHandler!();
        }
        break;

      case "synth.onStart":
        if (startHandler != null) {
          startHandler!();
        }
        break;
      case "speak.onComplete":
        if (completionHandler != null) {
          completionHandler!();
        }
        break;
      case "synth.onComplete":
        if (completionHandler != null) {
          completionHandler!();
        }
        break;
      case "speak.onPause":
        if (pauseHandler != null) {
          pauseHandler!();
        }
        break;
      case "speak.onContinue":
        if (continueHandler != null) {
          continueHandler!();
        }
        break;
      case "speak.onCancel":
        if (cancelHandler != null) {
          cancelHandler!();
        }
        break;
      case "speak.onError":
        if (errorHandler != null) {
          errorHandler!(call.arguments);
        }
        break;
      case 'speak.onProgress':
        if (progressHandler != null) {
          final args = call.arguments as Map<dynamic, dynamic>;
          progressHandler!(
            args['text'].toString(),
            int.parse(args['start'].toString()),
            int.parse(args['end'].toString()),
            args['word'].toString(),
          );
        }
        break;
      case "synth.onError":
        if (errorHandler != null) {
          errorHandler!(call.arguments);
        }
        break;
      default:
        print('Unknown method ${call.method}');
    }
  }

  Future<void> setAudioAttributesForNavigation() async {
    await _channel.invokeMethod('setAudioAttributesForNavigation');
  }
}
