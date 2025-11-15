import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'packages/flutter_tts_platform_interface/lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    cppHeaderOut: 'packages/flutter_tts_windows/windows/messages.g.h',
    cppSourceOut: 'packages/flutter_tts_windows/windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'flutter_tts'),
    dartPackageName: 'flutter_tts',
    kotlinOut:
        'packages/flutter_tts_android/android/src/main/kotlin/com/tundralabs/fluttertts/messages.g.kt',
    kotlinOptions: KotlinOptions(package: "com.tundralabs.fluttertts"),
    swiftOut: "packages/flutter_tts_macos/macos/Classes/message.g.swift",
  ),
)
enum FlutterTtsErrorCode {
  /// general error code for TTS engine not available.
  ttsNotAvailable,

  /// The TTS engine failed to initialize in n second.
  /// 1 second is the default timeout.
  /// e.g. Some Android custom ROMS may trim TTS service,
  /// and third party TTS engine may fail to initialize due to battery optimization.
  ttsInitTimeout,

  /// not supported on current os version
  notSupportedOSVersion,
}

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

class Voice {
  final String name;
  final String locale;
  String? gender;
  String? quality;
  String? identifier;

  Voice({
    required this.name,
    required this.locale,
    this.gender,
    this.quality,
    this.identifier,
  });
}

class TtsResult {
  final bool success;
  final String? message;

  TtsResult({required this.success, this.message});
}

class TtsProgress {
  final String text;
  final int start;
  final int end;
  final String word;

  TtsProgress({
    required this.text,
    required this.start,
    required this.end,
    required this.word,
  });
}

enum TtsPlatform { android, ios }

class TtsRateValidRange {
  final double minimum;
  final double normal;
  final double maximum;
  final TtsPlatform platform;

  TtsRateValidRange({
    required this.minimum,
    required this.normal,
    required this.maximum,
    required this.platform,
  });
}

@HostApi()
abstract class TtsHostApi {
  @async
  TtsResult speak(String text, bool forceFocus);

  @async
  TtsResult pause();

  @async
  TtsResult stop();

  @async
  TtsResult setSpeechRate(double rate);

  @async
  TtsResult setVolume(double volume);

  @async
  TtsResult setPitch(double pitch);

  @async
  TtsResult setVoice(Voice voice);

  @async
  TtsResult clearVoice();

  @async
  TtsResult awaitSpeakCompletion(bool awaitCompletion);

  @async
  List<String> getLanguages();

  @async
  List<Voice> getVoices();
}

@HostApi()
abstract class IosTtsHostApi extends TtsHostApi {
  @async
  TtsResult awaitSynthCompletion(bool awaitCompletion);

  @async
  TtsResult synthesizeToFile(
    String text,
    String fileName, [
    bool isFullPath = false,
  ]);

  @async
  TtsResult setSharedInstance(bool sharedSession);

  @async
  TtsResult autoStopSharedSession(bool autoStop);

  @async
  TtsResult setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, {
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  });

  @async
  TtsRateValidRange getSpeechRateValidRange();

  @async
  bool isLanguageAvailable(String language);

  @async
  TtsResult setLanguange(String language);
}

@HostApi()
abstract class AndroidTtsHostApi extends TtsHostApi {
  @async
  TtsResult awaitSynthCompletion(bool awaitCompletion);

  @async
  int? getMaxSpeechInputLength();

  @async
  TtsResult setEngine(String engine);

  @async
  List<String> getEngines();

  @async
  String? getDefaultEngine();

  @async
  Voice? getDefaultVoice();

  /// [Future] which invokes the platform specific method for synthesizeToFile
  @async
  TtsResult synthesizeToFile(
    String text,
    String fileName, [
    bool isFullPath = false,
  ]);

  @async
  bool isLanguageInstalled(String language);

  @async
  bool isLanguageAvailable(String language);

  @async
  Map<String, bool> areLanguagesInstalled(List<String> languages);

  @async
  TtsRateValidRange getSpeechRateValidRange();

  @async
  TtsResult setSilence(int timems);

  @async
  TtsResult setQueueMode(int queueMode);

  @async
  TtsResult setAudioAttributesForNavigation();
}

@HostApi()
abstract class MacosTtsHostApi extends TtsHostApi {
  @async
  TtsResult awaitSynthCompletion(bool awaitCompletion);

  @async
  TtsRateValidRange getSpeechRateValidRange();

  @async
  TtsResult setLanguange(String language);

  @async
  bool isLanguageAvailable(String language);
}

@FlutterApi()
abstract class TtsFlutterApi {
  void onSpeakStartCb();

  void onSpeakCompleteCb();

  void onSpeakPauseCb();

  void onSpeakResumeCb();

  void onSpeakCancelCb();

  void onSpeakProgressCb(TtsProgress progress);

  void onSpeakErrorCb(String error);

  void onSynthStartCb();

  void onSynthCompleteCb();

  void onSynthErrorCb(String error);
}
