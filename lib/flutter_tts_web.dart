import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'interop_types.dart';

enum TtsState { playing, stopped, paused, continued }

class FlutterTtsPlugin {
  static const String platformChannel = "flutter_tts";
  static late MethodChannel channel;
  bool awaitSpeakCompletion = false;

  TtsState ttsState = TtsState.stopped;

  Completer<dynamic>? _speechCompleter;

  bool get isPlaying => ttsState == TtsState.playing;

  bool get isStopped => ttsState == TtsState.stopped;

  bool get isPaused => ttsState == TtsState.paused;

  bool get isContinued => ttsState == TtsState.continued;

  static void registerWith(Registrar registrar) {
    channel =
        MethodChannel(platformChannel, const StandardMethodCodec(), registrar);
    final instance = FlutterTtsPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  late final SpeechSynthesisUtterance utterance;
  List<SpeechSynthesisVoice> voices = [];
  List<String> languages = [];
  Timer? t;
  bool supported = false;
  bool _primed = false;

  FlutterTtsPlugin() {
    try {
      utterance = SpeechSynthesisUtterance();
      _listeners();
      supported = true;
    } catch (e) {
      print('Initialization of TTS failed. Functions are disabled. Error: $e');
    }
  }

  void _listeners() {
    utterance.onStart = (JSAny e) {
      print('[TTS_WEB] EVENT: onStart fired');
      ttsState = TtsState.playing;
      channel.invokeMethod("speak.onStart", null);
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
      print('[TTS_WEB] EVENT: onEnd fired, completing _speechCompleter');
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter?.complete();
        _speechCompleter = null;
      }
      t?.cancel();
      channel.invokeMethod("speak.onComplete", null);
    }.toJS;

    utterance.onPause = (JSAny e) {
      print('[TTS_WEB] EVENT: onPause fired');
      ttsState = TtsState.paused;
      channel.invokeMethod("speak.onPause", null);
    }.toJS;

    utterance.onResume = (JSAny e) {
      print('[TTS_WEB] EVENT: onResume fired');
      ttsState = TtsState.continued;
      channel.invokeMethod("speak.onContinue", null);
    }.toJS;

    utterance.onError = (JSObject event) {
      print('[TTS_WEB] EVENT: onError fired, error: ${event["error"]}');
      ttsState = TtsState.stopped;
      if (_speechCompleter != null) {
        _speechCompleter = null;
      }
      t?.cancel();
      print(event); // Log the entire event object to get more details
      channel.invokeMethod("speak.onError", event["error"]);
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
      Map<String, dynamic> progressArgs = {
        'text': text,
        'start': charIndex,
        'end': endIndex,
        'word': word
      };
      channel.invokeMethod("speak.onProgress", progressArgs);
    }.toJS;

    synth.onVoicesChanged = (JSAny e) {
      channel.invokeMethod("synth.onVoicesChanged", null);
    }.toJS;
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (!supported) return;
    switch (call.method) {
      case 'speak':
        final text = call.arguments as String?;
        print('[TTS_WEB] speak called, awaitSpeakCompletion: $awaitSpeakCompletion, text length: ${text?.length}');
        if (awaitSpeakCompletion) {
          _speechCompleter = Completer();
          print('[TTS_WEB] Created _speechCompleter');
        }
        _speak(text);
        if (awaitSpeakCompletion) {
          print('[TTS_WEB] Returning _speechCompleter.future (will await)');
          return _speechCompleter?.future;
        }
        print('[TTS_WEB] speak returning without await');
        break;
      case 'awaitSpeakCompletion':
        awaitSpeakCompletion = (call.arguments as bool?) ?? false;
        return 1;
      case 'stop':
        _stop();
        return 1;
      case 'pause':
        _pause();
        return 1;
      case 'setLanguage':
        final language = call.arguments as String;
        _setLanguage(language);
        return 1;
      case 'getLanguages':
        return _getLanguages();
      case 'getVoices':
        return getVoices();
      case 'setVoice':
        final tmpVoiceMap =
            Map<String, String>.from(call.arguments as LinkedHashMap);
        return _setVoice(tmpVoiceMap);
      case 'setSpeechRate':
        final rate = call.arguments as double;
        _setRate(rate);
        return 1;
      case 'setVolume':
        final volume = call.arguments as double;
        _setVolume(volume);
        return 1;
      case 'setPitch':
        final pitch = call.arguments as double;
        _setPitch(pitch);
        return 1;
      case 'isLanguageAvailable':
        final lang = call.arguments as String;
        return _isLanguageAvailable(lang);
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The flutter_tts plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  void _speak(String? text) {
    print('[TTS_WEB] _speak called, text: ${text?.substring(0, text.length > 20 ? 20 : text.length)}..., ttsState: $ttsState, _primed: $_primed');
    if (text == null || text.isEmpty) {
      print('[TTS_WEB] _speak: text null/empty, returning');
      return;
    }
    if (ttsState == TtsState.stopped || ttsState == TtsState.paused) {
      // Prime Safari's Web Speech API on first use
      // Safari needs: speak → cancel → speak (mimics stop+play behavior)
      // See: https://qiita.com/kazuki_kuriyama/items/42e496ad3d25dd6b9436
      if (!_primed) {
        print('[TTS_WEB] Priming: creating empty utterance');
        final primeUtterance = SpeechSynthesisUtterance();
        primeUtterance.text = '';
        primeUtterance.volume = 0;
        print('[TTS_WEB] Priming: calling synth.speak(empty)');
        synth.speak(primeUtterance);
        print('[TTS_WEB] Priming: calling synth.cancel()');
        synth.cancel();  // Cancel immediately - this primes Safari
        print('[TTS_WEB] Priming: done, _primed = true');
        _primed = true;
      }
      utterance.text = text;
      if (ttsState == TtsState.paused) {
        print('[TTS_WEB] Calling synth.resume()');
        synth.resume();
      } else {
        print('[TTS_WEB] Calling synth.speak(utterance)');
        synth.speak(utterance);
        print('[TTS_WEB] synth.speak(utterance) returned');
      }
    } else {
      print('[TTS_WEB] _speak: ttsState is $ttsState, not stopped/paused, skipping');
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
  void _setLanguage(String language) {
    var targetList = synth.getVoices().toDart.where((e) {
      return e.lang.toLowerCase().startsWith(language.toLowerCase());
    });
    if (targetList.isNotEmpty) {
      utterance.voice = targetList.first;
      utterance.lang = targetList.first.lang;
    }
  }

  void _setVoice(Map<String?, String?> voice) {
    var tmpVoices = synth.getVoices().toDart;
    var targetList = tmpVoices.where((e) {
      return voice["name"] == e.name && voice["locale"] == e.lang;
    });
    if (targetList.isNotEmpty) {
      utterance.voice = targetList.first;
      utterance.lang = targetList.first.lang;
    }
  }

  bool _isLanguageAvailable(String? language) {
    if (voices.isEmpty) _setVoices();
    if (languages.isEmpty) _setLanguages();
    for (var lang in languages) {
      if (!language!.contains('-')) {
        lang = lang.split('-').first;
      }
      if (lang.toLowerCase() == language.toLowerCase()) return true;
    }
    return false;
  }

  List<String?>? _getLanguages() {
    if (voices.isEmpty) _setVoices();
    if (languages.isEmpty) _setLanguages();
    return languages;
  }

  void _setVoices() {
    voices = synth.getVoices().toDart;
  }

  Future<List<Map<String, String>>> getVoices() async {
    var tmpVoices = synth.getVoices().toDart;
    return tmpVoices
        .map((voice) => {"name": voice.name, "locale": voice.lang})
        .toList();
  }

  void _setLanguages() {
    var langs = <String>{};
    for (var v in voices) {
      langs.add(v.lang);
    }

    languages = langs.toList();
  }
}
