import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_tts/src/flutter_tts_platform_interface.dart';
import 'package:flutter_tts/src/flutter_tts_web_interop_types.dart';
import 'package:flutter_tts/src/messages.g.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

export 'package:flutter_tts/src/flutter_tts_web_interop_types.dart';

enum TtsState { playing, stopped, paused, continued }

class FlutterTtsWeb extends FlutterTtsPlatform {
  static void registerWith(Registrar registrar) {
    FlutterTtsPlatform.instance = FlutterTtsWeb();
  }

  bool isAwaitSpeakCompletion = false;

  TtsState ttsState = TtsState.stopped;

  Completer<TtsResult>? _speechCompleter;

  bool get isPlaying => ttsState == TtsState.playing;

  bool get isStopped => ttsState == TtsState.stopped;

  bool get isPaused => ttsState == TtsState.paused;

  bool get isContinued => ttsState == TtsState.continued;

  late final SpeechSynthesisUtterance utterance;
  List<SpeechSynthesisVoice> voices = [];
  List<String> languages = [];
  Timer? t;
  bool supported = false;

  FlutterTtsWeb() {
    try {
      utterance = SpeechSynthesisUtterance();
      _listeners();
      supported = true;
    } catch (e) {
      print('Initialization of TTS failed. Functions are disabled. Error: $e');
    }
  }

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
    _setPitch(pitch);
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setSpeechRate(double rate) async {
    _setRate(rate);
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setVoice(Voice voice) async {
    _setVoice(voice);
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> setVolume(double volume) async {
    _setVolume(volume);
    return ResultDart.success(TtsResult(success: true));
  }

  @override
  Future<ResultDart<TtsResult>> speak(String text, {bool focus = false}) async {
    _speak(text);
    if (isAwaitSpeakCompletion) {
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

  @override
  Future<ResultDart<TtsResult>> awaitSpeakCompletion(
    bool awaitCompletion,
  ) async {
    isAwaitSpeakCompletion = awaitCompletion;
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

  Future<bool> isLanguageAvailable(String lang) async {
    return _isLanguageAvailable(lang);
  }

  void _listeners() {
    utterance.onStart = (JSAny e) {
      ttsState = TtsState.playing;
      onSpeakStart?.call();
      var bLocal = (utterance.voice?.isLocalService ?? false);
      if (!bLocal) {
        t = Timer.periodic(Duration(seconds: 14), (t) {
          if (ttsState == TtsState.playing) {
            synth.pause();
            synth.resume();
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
    utterance.onEnd = (JSAny e) {
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter?.complete(TtsResult(success: true));
        _speechCompleter = null;
      }
      t?.cancel();
      onSpeakComplete?.call();
    }.toJS;

    utterance.onPause = (JSAny e) {
      ttsState = TtsState.paused;
      onSpeakPause?.call();
    }.toJS;

    utterance.onResume = (JSAny e) {
      ttsState = TtsState.continued;
      onSpeakResume?.call();
    }.toJS;

    utterance.onError = (JSObject event) {
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter = null;
      }
      t?.cancel();
      print(event); // Log the entire event object to get more details
      onSpeakError?.call(event["error"].toString());
    }.toJS;

    utterance.onBoundary = (JSObject event) {
      int charIndex = event['charIndex'] as int;
      String name = event['name'] as String;
      if (name == 'sentence') return;
      String text = utterance['text'] as String;
      int endIndex = charIndex;
      while (endIndex < text.length &&
          !RegExp(r'[\s,.!?]').hasMatch(text[endIndex])) {
        endIndex++;
      }
      String word = text.substring(charIndex, endIndex);
      TtsProgress progress = TtsProgress(
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
    if (ttsState == TtsState.stopped || ttsState == TtsState.paused) {
      utterance.text = text;
      if (ttsState == TtsState.paused) {
        synth.resume();
      } else {
        synth.speak(utterance);
      }
    }
  }

  void _stop() {
    if (ttsState != TtsState.stopped) {
      synth.cancel();
    }
  }

  void _pause() {
    if (ttsState == TtsState.playing || ttsState == TtsState.continued) {
      synth.pause();
    }
  }

  void _setRate(double rate) => utterance.rate = rate;
  void _setVolume(double volume) => utterance.volume = volume;
  void _setPitch(double pitch) => utterance.pitch = pitch;

  void _setVoice(Voice voice) {
    var tmpVoices = synth.getVoices().toDart;
    var targetList = tmpVoices.where((e) {
      return voice.name == e.name && voice.locale == e.lang;
    });

    if (targetList.isNotEmpty) {
      utterance.voice = targetList.first;
    }
  }

  bool _isLanguageAvailable(String? language) {
    if (voices.isEmpty) _updateVoices();
    if (languages.isEmpty) _updateLanguages();
    for (var lang in languages) {
      if (!language!.contains('-')) {
        lang = lang.split('-').first;
      }
      if (lang.toLowerCase() == language.toLowerCase()) return true;
    }
    return false;
  }

  List<String>? _getLanguages() {
    if (voices.isEmpty) _updateVoices();
    if (languages.isEmpty) _updateLanguages();
    return languages;
  }

  Future<List<Voice>> _getVoices() async {
    _updateVoices();
    return voices
        .map((voice) => Voice(name: voice.name, locale: voice.lang))
        .toList();
  }

  void _updateVoices() {
    voices = synth.getVoices().toDart;
  }

  void _updateLanguages() {
    var langs = <String>{};
    for (var v in voices) {
      langs.add(v.lang);
    }

    languages = langs.toList();
  }
}
