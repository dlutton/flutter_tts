import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_tts_platform_interface/flutter_tts_platform_interface.dart';
import 'package:flutter_tts_web/flutter_tts_web_interop_types.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

enum _TtsState { playing, stopped, paused, continued }

/// [FlutterTtsWeb] class for the web platform.
class FlutterTtsWeb extends FlutterTtsPlatform {
  /// Constructor for [FlutterTtsWeb].
  FlutterTtsWeb() {
    try {
      _utterance = SpeechSynthesisUtterance();
      _listeners();
      supported = true;
    } on Exception catch (e) {
      /// print is safe to use on flutter Web
      /// ignore: avoid_print
      print('Initialization of TTS failed. Functions are disabled. Error: $e');
    }
  }

  /// Registers the plugin with the Flutter engine.
  static void registerWith(Registrar registrar) {
    FlutterTtsPlatform.instance = FlutterTtsWeb();
  }

  /// Returns whether the TTS engine is currently playing.
  bool get isPlaying => _ttsState == _TtsState.playing;

  /// Returns whether the TTS engine is currently stopped.
  bool get isStopped => _ttsState == _TtsState.stopped;

  /// Returns whether the TTS engine is currently paused.
  bool get isPaused => _ttsState == _TtsState.paused;

  /// Returns whether the TTS engine is currently continued.
  bool get isContinued => _ttsState == _TtsState.continued;

  /// Returns whether the TTS engine is supported on the current platform.
  bool supported = false;

  bool _isAwaitSpeakCompletion = false;

  _TtsState _ttsState = _TtsState.stopped;

  Completer<TtsResult>? _speechCompleter;

  late final SpeechSynthesisUtterance _utterance;
  List<SpeechSynthesisVoice> _voices = [];
  List<String> _languages = [];
  Timer? _timer;

  @override
  Future<ResultDart<List<Voice>>> getVoices() async {
    try {
      return ResultDart.success(await _getVoices());
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  @override
  Future<ResultDart<TtsResult>> clearVoice() async {
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> pause() async {
    _pause();
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setPitch(double pitch) async {
    _utterance.pitch = pitch;
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setSpeechRate(double rate) async {
    _utterance.rate = rate;
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setVoice(Voice voice) async {
    _setVoice(voice);
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setVolume(double volume) async {
    _utterance.volume = volume;
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> speak(String text, {bool focus = false}) async {
    _speak(text);
    if (_isAwaitSpeakCompletion) {
      _speechCompleter = Completer<TtsResult>();
      return ResultDart.success(await _speechCompleter!.future);
    }

    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> stop() async {
    _stop();
    return ResultDart.success(TtsResult(success: true));
  }

  /// Await the completion of the current speech.
  @override
  Future<ResultDart<TtsResult>> awaitSpeakCompletion({
    required bool awaitCompletion,
  }) async {
    _isAwaitSpeakCompletion = awaitCompletion;
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<List<String>>> getLanguages() async {
    try {
      return ResultDart.success(_getLanguages() ?? []);
    } on Exception catch (e) {
      return ResultDart.error(e);
    }
  }

  /// Check if a language is available on the current platform.
  Future<bool> isLanguageAvailable(String lang) async {
    return _isLanguageAvailable(lang);
  }

  void _listeners() {
    _utterance.onStart = (JSAny e) {
      _ttsState = _TtsState.playing;
      onSpeakStart?.call();
      final bLocal = _utterance.voice?.isLocalService ?? false;
      if (!bLocal) {
        _timer = Timer.periodic(const Duration(seconds: 14), (t) {
          if (_ttsState == _TtsState.playing) {
            synth
              ..pause()
              ..resume();
          } else {
            t.cancel();
          }
        });
      }
    }.toJS;
    // js.JsFunction.withThis((e) {
    //   ttsState = TtsState.playing;
    //   channel.invokeMethod("speak.onStart", null);
    // });
    _utterance.onEnd = (JSAny e) {
      _ttsState = _TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter?.complete(TtsResult(success: true));
        _speechCompleter = null;
      }
      _timer?.cancel();
      onSpeakComplete?.call();
    }.toJS;

    _utterance.onPause = (JSAny e) {
      _ttsState = _TtsState.paused;
      onSpeakPause?.call();
    }.toJS;

    _utterance.onResume = (JSAny e) {
      _ttsState = _TtsState.continued;
      onSpeakResume?.call();
    }.toJS;

    _utterance.onError = (JSObject event) {
      _ttsState = _TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter = null;
      }
      _timer?.cancel();

      /// print is safe to use on flutter Web
      /// ignore: avoid_print
      print(event); // Log the entire event object to get more details
      onSpeakError?.call(event['error'].toString());
    }.toJS;

    _utterance.onBoundary = (JSObject event) {
      /// not sure about the impl, ignore for now
      /// ignore: cast_nullable_to_non_nullable,invalid_runtime_check_with_js_interop_types
      final charIndex = event['charIndex'] as int;

      /// not sure about the impl, ignore for now
      /// ignore: cast_nullable_to_non_nullable,invalid_runtime_check_with_js_interop_types
      final name = event['name'] as String;
      if (name == 'sentence') return;

      /// not sure about the impl, ignore for now
      /// ignore: cast_nullable_to_non_nullable,invalid_runtime_check_with_js_interop_types
      final text = _utterance['text'] as String;
      var endIndex = charIndex;
      while (endIndex < text.length &&
          !RegExp(r'[\s,.!?]').hasMatch(text[endIndex])) {
        endIndex++;
      }
      final word = text.substring(charIndex, endIndex);
      final progress = TtsProgress(
        text: text,
        start: charIndex,
        end: endIndex,
        word: word,
      );
      onSpeakProgress?.call(progress);
    }.toJS;
  }

  void _speak(String? text) {
    if (text == null || text.isEmpty) return;
    if (_ttsState == _TtsState.stopped || _ttsState == _TtsState.paused) {
      _utterance.text = text;
      if (_ttsState == _TtsState.paused) {
        synth.resume();
      } else {
        synth.speak(_utterance);
      }
    }
  }

  void _stop() {
    if (_ttsState != _TtsState.stopped) {
      synth.cancel();
    }
  }

  void _pause() {
    if (_ttsState == _TtsState.playing || _ttsState == _TtsState.continued) {
      synth.pause();
    }
  }

  void _setVoice(Voice voice) {
    final tmpVoices = synth.getVoices().toDart;
    final targetList = tmpVoices.where((e) {
      return voice.name == e.name && voice.locale == e.lang;
    });

    if (targetList.isNotEmpty) {
      _utterance.voice = targetList.first;
    }
  }

  bool _isLanguageAvailable(String? language) {
    if (_voices.isEmpty) _updateVoices();
    if (_languages.isEmpty) _updateLanguages();
    for (var lang in _languages) {
      if (!language!.contains('-')) {
        lang = lang.split('-').first;
      }
      if (lang.toLowerCase() == language.toLowerCase()) return true;
    }
    return false;
  }

  List<String>? _getLanguages() {
    if (_voices.isEmpty) _updateVoices();
    if (_languages.isEmpty) _updateLanguages();
    return _languages;
  }

  Future<List<Voice>> _getVoices() async {
    _updateVoices();
    return _voices
        .map((voice) => Voice(name: voice.name, locale: voice.lang))
        .toList();
  }

  void _updateVoices() {
    _voices = synth.getVoices().toDart;
  }

  void _updateLanguages() {
    final langs = <String>{};
    for (final v in _voices) {
      langs.add(v.lang);
    }

    _languages = langs.toList();
  }
}
